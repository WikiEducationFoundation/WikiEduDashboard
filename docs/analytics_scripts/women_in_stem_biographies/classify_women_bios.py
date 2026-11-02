"""Stage 3: classify each article into:
  - is_woman_bio: candidate biography of a woman?
  - stem_tier: 1 (core STEM), 2 (+ medicine/health), 3 (+ social sciences),
               or "" (excluded from all tiers)
  - status: "auto" (rule-decided) or "review" (needs Claude review)

All signals are additive. Missing Wikidata is never a subtractive exclusion;
articles with no Wikidata can still be classified via categories + lead
paragraph + short description.

Output (in data/):
  women_bios_auto.csv         — confidently auto-classified women bios
  women_bios_to_review.csv    — ambiguous: signals point woman+person but
                                tier is unclear, or woman/bio status itself
                                is borderline
  excluded_for_audit.csv      — random 100 articles classified as
                                not-woman-bio, for human spot-check audit
"""

import csv
import json
import os
import random
import re

DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'data')
CACHE_DIR = os.path.join(DATA_DIR, 'cache')
CONSOLIDATED = os.path.join(DATA_DIR, 'consolidated_articles.csv')

# Female-coded P21 (sex/gender) Q-IDs that count as positive
# "is a woman" evidence. Other gender Q-IDs (non-binary, intersex) are
# flagged for review rather than auto-included.
FEMALE_QIDS = {
    'Q6581072',   # female
    'Q1052281',   # trans woman / transgender female
}
NON_BINARY_OR_OTHER_QIDS = {
    'Q1097630',   # intersex
    'Q48270',     # non-binary
    'Q499327',    # genderfluid
    'Q189125',    # transgender (unspecified direction)
}
HUMAN_QID = 'Q5'

# Occupation-label keyword sets (case-insensitive substring match against
# the English label of any P106 Q-ID). The first list to match wins.
# These mirror benchmarks/african-american-stem/rubric.txt scope.

TIER_1_OCCUPATION_KEYWORDS = [
    # natural sciences
    'physicist', 'chemist', 'biologist', 'biochemist', 'microbiologist',
    'geneticist', 'physiologist', 'astronomer', 'astrophysicist',
    'cosmologist', 'geologist', 'geophysicist', 'oceanographer',
    'meteorologist', 'climatologist', 'ecologist', 'environmental scientist',
    'neuroscientist', 'molecular biologist', 'cell biologist',
    'evolutionary biologist', 'marine biologist', 'botanist', 'zoologist',
    'paleontologist', 'mycologist', 'entomologist', 'herpetologist',
    'ornithologist', 'ichthyologist', 'taxonomist', 'naturalist',
    'mineralogist', 'crystallographer', 'volcanologist', 'seismologist',
    'limnologist', 'hydrologist', 'geographer',  # physical geographer
    # math / cs
    'mathematician', 'statistician', 'computer scientist',
    'software engineer', 'software developer', 'programmer',
    'data scientist', 'cryptographer', 'algorithm',
    # engineering & applied STEM
    'engineer',  # broad — catches civil engineer, electrical engineer, etc.
    'inventor', 'aerospace', 'astronaut', 'cosmonaut',
    'materials scientist', 'nanotechnologist', 'roboticist',
    'biomedical scientist', 'bioengineer', 'biotechnologist',
    'pharmacologist',  # research-primary; clinical pharm is Tier 2
    'agronomist', 'food scientist',
    # research-coded
    'researcher',  # too broad alone; pair-check with stem categories
    'scientist',
]

TIER_2_OCCUPATION_KEYWORDS = [
    'physician', 'surgeon', 'cardiologist', 'oncologist', 'pediatrician',
    'psychiatrist', 'radiologist', 'dermatologist', 'gynecologist',
    'obstetrician', 'urologist', 'neurologist', 'pathologist',
    'gastroenterologist', 'hematologist', 'rheumatologist',
    'ophthalmologist', 'orthopedic', 'anesthesiologist', 'epidemiologist',
    'public health', 'doctor of medicine',
    'nurse', 'dentist', 'pharmacist', 'midwife', 'veterinarian',
    'dietitian', 'physical therapist', 'occupational therapist',
    'medical', 'clinical',  # generic — catches "medical researcher" tho;
    # we rely on Tier 1 taking precedence
]

TIER_3_OCCUPATION_KEYWORDS = [
    'psychologist', 'sociologist', 'anthropologist', 'economist',
    'political scientist', 'archaeologist', 'linguist',
    'demographer', 'criminologist', 'urban planner',
    'social worker',  # peripheral; flag for review really
    'social scientist',
]

# Clearly-NON-STEM occupation labels. If ALL of a person's P106 labels
# match these and NONE match any tier list, we auto-exclude (no review
# needed). Conservative list — only unambiguous non-STEM roles. Excludes
# "writer", "professor", "academic" because STEM communicators / general
# academics often have those alongside a real STEM occupation but
# sometimes alone.
NON_STEM_OCCUPATION_KEYWORDS = [
    # entertainment & arts
    'actor', 'actress', 'singer', 'rapper', 'musician', 'composer',
    'dancer', 'choreographer', 'comedian', 'model', 'fashion designer',
    'illustrator', 'cartoonist', 'painter', 'sculptor', 'photographer',
    'film director', 'film producer', 'screenwriter', 'voice actor',
    'television presenter', 'radio personality', 'host', 'youtuber',
    'podcaster', 'drag queen',
    # athletes
    'basketball player', 'football player', 'footballer', 'soccer player',
    'tennis player', 'swimmer', 'gymnast', 'athlete', 'baseball player',
    'hockey player', 'ice hockey player', 'runner', 'boxer', 'wrestler',
    'cricketer', 'golfer', 'cyclist', 'skier', 'skater', 'figure skater',
    'sprinter', 'high jumper', 'long jumper', 'rower', 'fencer',
    'volleyball player', 'softball player', 'lacrosse player',
    'water polo player', 'rugby player', 'sports coach', 'coach',
    'pole vaulter', 'shot putter', 'discus thrower', 'martial artist',
    'mixed martial artist', 'racing driver',
    # politics & law
    'politician', 'lawyer', 'attorney', 'judge', 'diplomat', 'governor',
    'senator', 'congresswoman', 'congressman', 'representative',
    'mayor', 'ambassador', 'minister', 'prime minister', 'president',
    'vice president',
    # royalty & religion
    'monarch', 'queen', 'king', 'prince', 'princess', 'duke', 'duchess',
    'countess', 'baroness', 'empress', 'emperor', 'royal',
    'nun', 'monk', 'priest', 'pastor', 'missionary', 'rabbi', 'imam',
    'pope', 'cardinal', 'bishop', 'theologian',
    # military
    'soldier', 'general', 'admiral', 'officer', 'sailor',
    # business
    'businessperson', 'businesswoman', 'businessman', 'entrepreneur',
    'ceo', 'executive', 'chief executive officer', 'banker', 'investor',
    'hedge fund manager', 'venture capitalist',
    # activist / general public figure
    'activist', 'philanthropist', 'suffragette', 'suffragist',
    'abolitionist', 'human rights activist', 'feminist',
    'civil rights leader', 'beauty pageant contestant',
    # food
    'chef', 'restaurateur', 'sommelier',
    # other
    'astrologer', 'spiritual leader', 'preacher',
]

# Words that strongly indicate NON-bio article subjects (event, work, place).
NON_PERSON_CATEGORY_KEYWORDS = [
    # works / media
    'films', 'albums', 'songs', 'novels', 'short stories', 'video games',
    'television series', 'episodes', 'books', 'memoirs', 'autobiographies',
    'plays', 'poems', 'poetry collections', 'paintings', 'sculptures',
    'musical compositions', 'documentaries', 'manuscripts',
    'comic books', 'manga',
    # organizations / institutions
    'companies', 'corporations', 'banks', 'organizations',
    'universities', 'colleges', 'museums', 'awards',
    # places
    'rivers', 'mountains', 'lakes', 'islands', 'cities', 'towns',
    'villages', 'counties', 'provinces', 'states of', 'neighborhoods',
    # events
    'battles', 'wars', 'treaties', 'elections', 'protests', 'massacres',
    # natural / abstract
    'species', 'genera', 'genus', 'plants', 'animals', 'fungi',
    'asteroids', 'comets', 'galaxies', 'craters',
    'theorems', 'equations', 'algorithms', 'concepts in', 'theories',
    'philosophical', 'diseases', 'syndromes', 'symptoms',
    'chemical compounds', 'biochemistry stubs', 'organic compounds',
    'inorganic compounds', 'minerals', 'rocks',
    # structures
    'buildings', 'churches', 'stadiums', 'bridges', 'tunnels',
    'roads', 'highways', 'airports', 'railway stations',
    'ships', 'aircraft', 'spacecraft',
]

WOMEN_CAT_RE = re.compile(r'\b(women|female|girls?)\b', re.I)

# Patterns hinting at a person in a category name
PERSON_CAT_KEYWORDS_RE = re.compile(
    r'\b(births|deaths|alumni|people|scientist|physicist|chemist|biologist|'
    r'mathematician|engineer|astronomer|astronaut|inventor|professor|'
    r'doctor|physician|surgeon|nurse|psychologist|sociologist|anthropologist|'
    r'economist|archaeologist|linguist|geographer|geologist|researcher|'
    r'academic|educator|teacher|author|writer|journalist|politician|'
    r'actress|actor|singer|musician|painter|sculptor|athlete|player|'
    r'activist|philanthropist|nun|priest|rabbi|imam|judge|lawyer|'
    r'general|admiral|officer|soldier|sailor|spy|monarch|king|queen|'
    r'duchess|countess|empress|princess|baroness|presidents?|ministers?|'
    r'biography|biographies)\b',
    re.I,
)

# Female pronoun matches in a lead paragraph
SHE_HER_RE = re.compile(r'\b(she|her|hers|herself)\b')
HE_HIM_RE = re.compile(r'\b(he|him|his|himself)\b')
SINGULAR_THEY_RE = re.compile(r'\bthey\b')

# Roles in a short-description that imply a person.
PERSON_ROLE_IN_DESC_RE = re.compile(
    r'\b(scientist|physicist|chemist|biologist|mathematician|engineer|'
    r'astronomer|astronaut|inventor|professor|physician|surgeon|nurse|'
    r'doctor|psychologist|sociologist|anthropologist|economist|'
    r'archaeologist|linguist|researcher|academic|educator|teacher|'
    r'author|writer|poet|journalist|politician|actress|actor|singer|'
    r'musician|painter|sculptor|athlete|activist|nun|priest|'
    r'monarch|queen|princess|duchess|baroness|countess|empress|'
    r'biographer|geographer|geologist|neuroscientist|biochemist|'
    r'geneticist|physiologist|botanist|zoologist|paleontologist)\b',
    re.I,
)


def load_json(name, default):
    path = os.path.join(CACHE_DIR, name)
    if not os.path.exists(path):
        return default
    with open(path, encoding='utf-8') as f:
        return json.load(f)


def first_match_tier(occupation_labels):
    """Return (tier, matched_label) or (None, None). Tier 1 > 2 > 3."""
    lowered = [(l or '').lower() for l in occupation_labels]
    for kw in TIER_1_OCCUPATION_KEYWORDS:
        for lbl in lowered:
            if kw in lbl:
                return 1, lbl
    for kw in TIER_2_OCCUPATION_KEYWORDS:
        for lbl in lowered:
            if kw in lbl:
                return 2, lbl
    for kw in TIER_3_OCCUPATION_KEYWORDS:
        for lbl in lowered:
            if kw in lbl:
                return 3, lbl
    return None, None


def category_tier_evidence(categories):
    """Inspect categories for tier-keyed matches. Returns dict tier->[cats]."""
    found = {1: [], 2: [], 3: []}
    for cat in categories:
        cl = cat.lower()
        # Tier 1 — STEM words in category
        if any(kw in cl for kw in TIER_1_OCCUPATION_KEYWORDS):
            found[1].append(cat)
            continue
        if any(kw in cl for kw in TIER_2_OCCUPATION_KEYWORDS):
            found[2].append(cat)
            continue
        if any(kw in cl for kw in TIER_3_OCCUPATION_KEYWORDS):
            found[3].append(cat)
    return found


BIRTH_DEATH_CAT_RE = re.compile(
    r'^\d{1,4}s?\s+(births|deaths)$|^Living people$|'
    r'^People (from|of)\s|^\d{4} (births|deaths)\b',
    re.I,
)


def looks_like_person_lead(lead):
    """First-sentence-ish person heuristics. Tight: needs explicit pronoun
    OR a profession word in the opening sentence. (Earlier 'was/is a/an X'
    pattern was too greedy — matched chemical-compound and book leads.)"""
    if not lead:
        return False, []
    reasons = []
    sentence = lead.split('. ', 1)[0]
    if SHE_HER_RE.search(sentence):
        reasons.append('she/her in opening sentence')
    if HE_HIM_RE.search(sentence):
        reasons.append('he/him in opening sentence')
    if PERSON_ROLE_IN_DESC_RE.search(sentence):
        reasons.append('profession word in opening sentence')
    # "(born YYYY)" / "(YYYY–YYYY)" is a strong person tell
    if re.search(r'\(\s*born\s+\d{4}\)|\(\s*\d{4}\s*[\-–]\s*\d{4}\s*\)', sentence):
        reasons.append('birth-year-in-parens pattern')
    return bool(reasons), reasons


def categories_say_person(categories):
    """Return list of categories that strongly indicate a person subject."""
    matches = []
    for cat in categories:
        if BIRTH_DEATH_CAT_RE.search(cat):
            matches.append(cat)
            continue
        # 'American scientists', 'Women physicists', 'XYZ alumni' — any cat
        # that contains a clearly-person-role keyword AND is not in the
        # non-person blocklist.
        cl = cat.lower()
        if any(kw in cl for kw in NON_PERSON_CATEGORY_KEYWORDS):
            continue
        if PERSON_CAT_KEYWORDS_RE.search(cat):
            matches.append(cat)
    return matches


def looks_female_lead(lead):
    """Female-pronoun evidence anywhere in the lead."""
    if not lead:
        return False, []
    she = len(SHE_HER_RE.findall(lead))
    he = len(HE_HIM_RE.findall(lead))
    reasons = []
    if she >= 1 and she >= he:
        reasons.append(f'she-pronouns {she} vs he-pronouns {he}')
        return True, reasons
    return False, reasons


def looks_male_lead(lead):
    """Male-pronoun evidence anywhere in the lead. Used to suppress
    'STEM-without-female-evidence' review flag when the article is
    clearly about a man."""
    if not lead:
        return False, []
    she = len(SHE_HER_RE.findall(lead))
    he = len(HE_HIM_RE.findall(lead))
    if he >= 2 and he > she:
        return True, [f'he-pronouns {he} vs she-pronouns {she}']
    return False, []


def all_p106_are_non_stem(occupation_labels):
    """True iff every label matches NON_STEM_OCCUPATION_KEYWORDS and none
    matches any tier list. Returns (bool, matched_labels)."""
    if not occupation_labels:
        return False, []
    lowered = [(l or '').lower() for l in occupation_labels if l]
    if not lowered:
        return False, []
    # Any STEM keyword present → not all-non-STEM
    stem_kws = (TIER_1_OCCUPATION_KEYWORDS + TIER_2_OCCUPATION_KEYWORDS
                + TIER_3_OCCUPATION_KEYWORDS)
    for lbl in lowered:
        if any(kw in lbl for kw in stem_kws):
            return False, []
    # Every label must match at least one non-STEM keyword
    matched = []
    for lbl in lowered:
        hit = next((kw for kw in NON_STEM_OCCUPATION_KEYWORDS if kw in lbl), None)
        if not hit:
            return False, []
        matched.append(f'{lbl} (matches "{hit}")')
    return True, matched


def main():
    qd = load_json('qids_and_shortdescs.json', {})
    cats = load_json('categories.json', {})
    leads = load_json('leads.json', {})
    ents = load_json('wikidata_entities.json', {})
    labels = load_json('qid_labels.json', {})

    rows_out_auto = []
    rows_out_review = []
    excluded_audit_pool = []

    with open(CONSOLIDATED, newline='', encoding='utf-8') as f:
        consolidated = list(csv.DictReader(f))

    for row in consolidated:
        title = row['title']
        article_signals = {
            'is_woman_evidence': [],
            'is_person_evidence': [],
            'is_not_person_evidence': [],
            'tier1_evidence': [],
            'tier2_evidence': [],
            'tier3_evidence': [],
            'ambiguous_gender_flags': [],
        }
        qd_row = qd.get(title, {})
        qid = qd_row.get('qid') or ''
        shortdesc = qd_row.get('short_desc') or ''
        title_cats = cats.get(title, []) or []
        lead = leads.get(title, '') or ''
        ent = ents.get(qid, {}) if qid else {}
        p31 = ent.get('p31', []) or []
        p21 = ent.get('p21', []) or []
        p106 = ent.get('p106', []) or []
        wd_desc = ent.get('description', '') or ''

        occ_labels = [labels.get(q, '') for q in p106]
        p106_pretty = ', '.join(filter(None, occ_labels))

        # ── is_person? ──
        # P31=Q5 is the gold standard. Plus, category & lead signals
        # required to be strong (not just "is/was a..." patterns).
        if HUMAN_QID in p31:
            article_signals['is_person_evidence'].append('wd P31=Q5')
        p31_non_human = [q for q in p31 if q != HUMAN_QID]
        if p31_non_human and HUMAN_QID not in p31:
            article_signals['is_not_person_evidence'].append(
                f'wd P31 non-human: {"|".join(p31_non_human)}'
            )
        person_cats = categories_say_person(title_cats)
        for cat in person_cats[:3]:
            article_signals['is_person_evidence'].append(f'cat: {cat}')
        for cat in title_cats:
            if any(kw in cat.lower() for kw in NON_PERSON_CATEGORY_KEYWORDS):
                article_signals['is_not_person_evidence'].append(f'cat: {cat}')
                break
        person_lead_ok, person_lead_reasons = looks_like_person_lead(lead)
        if person_lead_ok:
            article_signals['is_person_evidence'].extend(
                [f'lead: {r}' for r in person_lead_reasons]
            )
        # short desc says profession
        if PERSON_ROLE_IN_DESC_RE.search(shortdesc) or PERSON_ROLE_IN_DESC_RE.search(wd_desc):
            article_signals['is_person_evidence'].append('desc names a profession')

        # ── is_woman? (additive) ──
        if any(q in FEMALE_QIDS for q in p21):
            article_signals['is_woman_evidence'].append(f'wd P21 female-coded ({"|".join(p21)})')
        if p21 and not any(q in FEMALE_QIDS for q in p21):
            # any other P21 value → flag
            if any(q in NON_BINARY_OR_OTHER_QIDS for q in p21):
                article_signals['ambiguous_gender_flags'].append(
                    f'wd P21 non-female ({"|".join(p21)})'
                )
        for cat in title_cats:
            if WOMEN_CAT_RE.search(cat):
                # Need it to be a women+person category, not "Women's films"
                if PERSON_CAT_KEYWORDS_RE.search(cat) or any(
                    kw in cat.lower()
                    for kw in TIER_1_OCCUPATION_KEYWORDS
                    + TIER_2_OCCUPATION_KEYWORDS
                    + TIER_3_OCCUPATION_KEYWORDS
                ):
                    article_signals['is_woman_evidence'].append(f'cat: {cat}')
        female_lead_ok, female_lead_reasons = looks_female_lead(lead)
        if female_lead_ok:
            article_signals['is_woman_evidence'].extend(
                [f'lead: {r}' for r in female_lead_reasons]
            )

        # ── STEM tier? ──
        tier_from_occ, occ_match = first_match_tier(occ_labels)
        if tier_from_occ:
            article_signals[f'tier{tier_from_occ}_evidence'].append(
                f'p106 occupation: {occ_match}'
            )
        cat_tier_ev = category_tier_evidence(title_cats)
        for t in (1, 2, 3):
            for c in cat_tier_ev[t]:
                article_signals[f'tier{t}_evidence'].append(f'cat: {c}')
        # Short desc / wd_desc keyword-match
        for kw in TIER_1_OCCUPATION_KEYWORDS:
            if kw in shortdesc.lower() or kw in wd_desc.lower():
                article_signals['tier1_evidence'].append(f'desc: {kw}')
                break
        if not article_signals['tier1_evidence']:
            for kw in TIER_2_OCCUPATION_KEYWORDS:
                if kw in shortdesc.lower() or kw in wd_desc.lower():
                    article_signals['tier2_evidence'].append(f'desc: {kw}')
                    break
        if not article_signals['tier1_evidence'] and not article_signals['tier2_evidence']:
            for kw in TIER_3_OCCUPATION_KEYWORDS:
                if kw in shortdesc.lower() or kw in wd_desc.lower():
                    article_signals['tier3_evidence'].append(f'desc: {kw}')
                    break

        # P31 is dispositive when present:
        #   - has Q5 → person (even if there's a side category that looks
        #     like a non-person blocklist hit)
        #   - has non-Q5 P31s only → not a person, no matter what the
        #     lead/cats look like.
        # When P31 is missing entirely, fall back to category + lead.
        if HUMAN_QID in p31:
            is_person = True
        elif p31:
            is_person = False
        else:
            is_person = (
                len(article_signals['is_person_evidence']) >= 1
                and not article_signals['is_not_person_evidence']
            )
        is_woman = is_person and bool(article_signals['is_woman_evidence'])
        ambiguous_gender = is_person and bool(article_signals['ambiguous_gender_flags'])

        if article_signals['tier1_evidence']:
            tier = 1
        elif article_signals['tier2_evidence']:
            tier = 2
        elif article_signals['tier3_evidence']:
            tier = 3
        else:
            tier = None

        out_row = {
            'title': title,
            'qid': qid,
            'short_desc': shortdesc,
            'wd_description': wd_desc,
            'p21': '|'.join(p21),
            'p106_labels': p106_pretty,
            'lead_excerpt': (lead or '')[:300].replace('\n', ' '),
            'is_person': is_person,
            'is_woman': is_woman,
            'ambiguous_gender': ambiguous_gender,
            'tier': tier or '',
            'tier1_evidence': '; '.join(article_signals['tier1_evidence']),
            'tier2_evidence': '; '.join(article_signals['tier2_evidence']),
            'tier3_evidence': '; '.join(article_signals['tier3_evidence']),
            'is_person_evidence': '; '.join(article_signals['is_person_evidence']),
            'is_woman_evidence': '; '.join(article_signals['is_woman_evidence']),
            'is_not_person_evidence': '; '.join(article_signals['is_not_person_evidence']),
            'ambiguous_gender_flags': '; '.join(article_signals['ambiguous_gender_flags']),
            'student_count': row['student_count'],
            'students': row['students'],
            'earliest_start_date': row['earliest_start_date'],
            'terms': row['terms'],
        }

        # ── Auto-exclude obvious-non-STEM-occupation cases ──
        # Conservative default: if Wikidata's P106 occupation list is
        # non-empty but didn't match any STEM tier (via keywords across
        # P106, categories, or descriptions), trust that and exclude.
        # The only case we route to manual review is when P106 is empty
        # AND tier_evidence is also empty — we genuinely don't know.
        all_non_stem, non_stem_matches = all_p106_are_non_stem(occ_labels)
        has_any_tier_ev = bool(
            article_signals['tier1_evidence']
            or article_signals['tier2_evidence']
            or article_signals['tier3_evidence']
        )
        if occ_labels and not has_any_tier_ev:
            if all_non_stem:
                out_row['auto_exclude_reason'] = (
                    'all p106 occupations are non-STEM: '
                    + '; '.join(non_stem_matches)
                )
            else:
                out_row['auto_exclude_reason'] = (
                    'p106 occupations don\'t match STEM tiers: '
                    + '|'.join(filter(None, occ_labels))
                )
        else:
            out_row['auto_exclude_reason'] = ''

        # Decide auto vs review
        review_needed = False
        review_reason = []
        if is_woman:
            if tier is None:
                if occ_labels:
                    # Has occupation data and it doesn't match STEM. Trust it.
                    pass  # falls through to exclusion below
                else:
                    # No P106 occupation; categories/lead didn't yield tier.
                    # Genuinely ambiguous → review.
                    review_needed = True
                    review_reason.append(
                        'woman bio with no Wikidata occupation; review needed'
                    )
        elif ambiguous_gender:
            review_needed = True
            review_reason.append('non-female-coded gender on Wikidata; verify')
        elif is_person and (
            article_signals['tier1_evidence']
            or article_signals['tier2_evidence']
            or article_signals['tier3_evidence']
        ):
            # Person + STEM evidence but no female evidence. If the lead
            # is clearly male-coded, skip review (it's a man).
            male_lead_ok, _ = looks_male_lead(lead)
            wd_p21_male = any(q == 'Q6581097' for q in p21)
            if not male_lead_ok and not wd_p21_male:
                review_needed = True
                review_reason.append('STEM-looking person without female evidence')
        out_row['review_reason'] = '; '.join(review_reason)

        if review_needed:
            rows_out_review.append(out_row)
        elif is_woman and tier is not None:
            rows_out_auto.append(out_row)
        else:
            excluded_audit_pool.append(out_row)

    # Sample 100 excluded for audit
    rng = random.Random(42)
    if len(excluded_audit_pool) > 100:
        audit_sample = rng.sample(excluded_audit_pool, 100)
    else:
        audit_sample = excluded_audit_pool

    fieldnames = [
        'title', 'qid', 'short_desc', 'wd_description', 'p21', 'p106_labels',
        'lead_excerpt', 'is_person', 'is_woman', 'ambiguous_gender', 'tier',
        'tier1_evidence', 'tier2_evidence', 'tier3_evidence',
        'is_person_evidence', 'is_woman_evidence', 'is_not_person_evidence',
        'ambiguous_gender_flags', 'auto_exclude_reason', 'review_reason',
        'student_count', 'students', 'earliest_start_date', 'terms',
    ]

    def write(path, rows):
        with open(path, 'w', newline='', encoding='utf-8') as f:
            w = csv.DictWriter(f, fieldnames=fieldnames)
            w.writeheader()
            for r in rows:
                w.writerow(r)

    write(os.path.join(DATA_DIR, 'women_bios_auto.csv'), rows_out_auto)
    write(os.path.join(DATA_DIR, 'women_bios_to_review.csv'), rows_out_review)
    write(os.path.join(DATA_DIR, 'excluded_for_audit.csv'), audit_sample)

    print(f'auto: {len(rows_out_auto)}')
    print(f'  tier 1: {sum(1 for r in rows_out_auto if r["tier"] == 1)}')
    print(f'  tier 2: {sum(1 for r in rows_out_auto if r["tier"] == 2)}')
    print(f'  tier 3: {sum(1 for r in rows_out_auto if r["tier"] == 3)}')
    print(f'review: {len(rows_out_review)}')
    print(f'excluded: {len(excluded_audit_pool)} (random {len(audit_sample)} written to excluded_for_audit.csv)')


if __name__ == '__main__':
    main()
