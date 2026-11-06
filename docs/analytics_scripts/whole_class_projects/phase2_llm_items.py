"""Phase 2 of PLAN.md: build blinded items for LLM quality grading.

Samples pages from wcp_analysis.phase2_article_metrics — class pages
(class_byte_share >= 0.5, not deleted) with 500-4,000 words added, at most one
page per course (with WCP_MULTI_PAGE=1, up to 3 per whole-class course and 2
per comparison course) — stratified by group (whole-class core vs matched and
same-instructor comparisons) and era (start before 2023 vs 2023+).

For each page, the added passages are the paragraphs of the end-of-window
wikitext that are mostly new relative to the baseline. Up to MAX_CLAIMS cited
sentences from those passages become claims; each claim's citation is parsed,
and its source is fetched (HTML or PDF) and cut to the excerpt windows that
best match the claim. Scholarly citations are first looked up in OpenAlex
for an open-access copy; failed fetches fall back to the citation's archive
link and then the Wayback Machine capture nearest the citing revision.
Unreachable sources are recorded with a status, never guessed.

Items carry no course, mode, date or username information. The key linking
items to courses and strata is written separately.

  python3 phase2_llm_items.py [N_PER_STRATUM]

Writes data/phase2_llm/items.jsonl, data/phase2_llm/key.jsonl, and caches
fetched sources in data/cache/sources/.
"""
import gzip
import hashlib
import html
import json
import os
import random
import re
import subprocess
import sys
import tempfile
import time
from html.parser import HTMLParser

import requests

HERE = os.path.dirname(os.path.abspath(__file__))
BUNDLES = os.path.join(HERE, 'data/phase2/bundles')
OUT_DIR = os.path.join(HERE, os.environ.get('WCP_LLM_DIR', 'data/phase2_llm'))
SOURCE_CACHE = os.path.join(HERE, 'data/cache/sources')
DB = ['mysql', '--no-defaults', '-u', 'wiki', '-pwikiedu', '-h', '127.0.0.1', '--batch', '--skip-column-names',
      'wcp_analysis']
USER_AGENT = 'WikiEduDashboard-research/0.1 (https://dashboard.wikiedu.org; whole-class projects study)'
MAX_CLAIMS = 5
EXCERPT_WINDOW = 2000
EXCERPT_WINDOWS = 4  # up to ~8,000 characters of each source
PASSAGE_LIMIT = 6000
WAYBACK_SPACING = 5  # seconds between Wayback requests
LAST_WAYBACK = 0.0
NEW_PARAGRAPH = 0.7  # share of a paragraph's shingles absent from baseline
WORD_RE = re.compile(r'[a-z0-9]+')
STOPWORDS = set('the a an of and or in on to for by with as at from that this is was were be been are its it '
                'which who their his her they he she has have had not but also into than more most such'.split())


def query(sql):
    out = subprocess.run(DB + ['-e', sql], capture_output=True, text=True, check=True).stdout
    return [line.split('\t') for line in out.splitlines()]


MAX_PER_COURSE = {'whole_class': 3, 'comparison': 2}


def sample(per_stratum, rng):
    rows = query("""
        SELECT m.course_id, m.page_id, YEAR(c.start) >= 2023 AS post,
               MAX(s.role = 'cohort' AND s.tier IN ('A_confirmed', 'B_history_only')) AS whole,
               MAX(s.role IN ('matched', 'same_instructor')) AS comparison
        FROM phase2_article_metrics m
        JOIN comparison_set s ON s.course_id = m.course_id
        JOIN wcp_sanitized.courses c ON c.id = m.course_id
        WHERE m.deleted = 0 AND m.redirected = 0 AND m.class_byte_share >= 0.5
          AND m.words_added BETWEEN 500 AND 4000
        GROUP BY m.course_id, m.page_id, post""")
    strata = {}
    for course_id, page_id, post, whole, comparison in rows:
        group = 'whole_class' if whole == '1' else 'comparison' if comparison == '1' else None
        if group:
            strata.setdefault((group, 'post2023' if post == '1' else 'pre2023'), []).append((int(course_id), int(page_id)))
    picked = []
    for key in sorted(strata):
        pages = strata[key]
        rng.shuffle(pages)
        per_course = {}
        limit = MAX_PER_COURSE[key[0]] if os.environ.get('WCP_MULTI_PAGE') else 1
        count = 0
        for course_id, page_id in pages:
            if per_course.get(course_id, 0) >= limit:
                continue
            per_course[course_id] = per_course.get(course_id, 0) + 1
            picked.append((key, course_id, page_id))
            count += 1
            if count >= per_stratum:
                break
    return picked


# --- wikitext handling -------------------------------------------------------

def shingles(text):
    words = WORD_RE.findall(text.lower())
    return set(tuple(words[i:i + 5]) for i in range(max(len(words) - 4, 0)))


REF_FULL = re.compile(r'<ref(?:\s+name\s*=\s*"?([^">/]+?)"?)?\s*>(.*?)</ref>', re.S | re.I)
REF_SHORT = re.compile(r'<ref\s+name\s*=\s*"?([^">/]+?)"?\s*/>', re.I)


def named_refs(text):
    return {m.group(1).strip(): m.group(2) for m in REF_FULL.finditer(text) if m.group(1)}


def added_paragraphs(baseline, end):
    base = shingles(baseline)
    out = []
    for para in re.split(r'\n\s*\n', end):
        if para.strip().startswith(('{{', '[[File:', '[[Image:', '{|', '==')) and '\n' not in para.strip():
            continue
        sh = shingles(REF_FULL.sub('', para))
        if len(sh) >= 8 and len(sh - base) / len(sh) >= NEW_PARAGRAPH:
            out.append(para.strip())
    return out


def plain(wikitext):
    text = re.sub(r'\[\[(?:[^|\]]*\|)?([^\]]*)\]\]', r'\1', wikitext)
    text = re.sub(r"'{2,}", '', text)
    for _ in range(3):  # nested templates
        text = re.sub(r'\{\{[^{}]*\}\}', '', text, flags=re.S)
    text = re.sub(r'<!--.*?-->', '', text, flags=re.S)
    text = re.sub(r'[ \t]+', ' ', text)
    return re.sub(r'\n{3,}', '\n\n', text).strip()


def cite_fields(ref):
    fields = {}
    for key in ('title', 'url', 'doi', 'author', 'last', 'first', 'publisher', 'journal', 'work', 'website',
                'date', 'year', 'isbn', 'page', 'pages', 'archive-url', 'chapter'):
        m = re.search(r'\|\s*' + re.escape(key) + r'\s*=\s*([^|}]*)', ref)
        if m and m.group(1).strip():
            fields[key] = m.group(1).strip()
    if 'url' not in fields:
        m = re.search(r'https?://[^\s\]|}<]+', ref)
        if m:
            fields['url'] = m.group(0)
    return fields


def passage_with_markers(paras, refs):
    """Plain-text passage with [n] markers, plus the claims (cited sentences)."""
    claims = []
    marked = []
    for para in paras:
        counter = {'text': para}

        def mark(m, is_short=False):
            name = m.group(1).strip() if m.group(1) else None
            body = refs.get(name) if is_short else m.group(2)
            if body is None:
                return ''
            claims.append({'ref': body, 'n': len(claims) + 1})
            return f' [{len(claims)}]'
        text = REF_SHORT.sub(lambda m: mark(m, True), counter['text'])
        text = REF_FULL.sub(mark, text)
        marked.append(plain(text))
    passage = '\n\n'.join(marked)
    for claim in claims:
        claim['sentence'] = sentence_before(passage, f' [{claim["n"]}]')
    return passage, claims


def sentence_before(passage, marker):
    """The sentence a citation marker closes: back to the previous sentence end,
    heading or paragraph break, forward through the marker and any adjacent
    markers."""
    pos = passage.find(marker)
    if pos < 0:
        return ''
    end = pos + len(marker)
    while m := re.match(r' ?\[\d+\]', passage[end:]):
        end += m.end()
    head = passage[:pos]
    head = re.sub(r'(\s*\[\d+\])+$', '', head)  # markers just before this one
    boundaries = re.finditer(r'(?:[.!?]\S*|\])\s+(?=[A-Z0-9"“(])', head)
    cut = max(head.rfind('\n'), *(m.end() for m in boundaries), 0)
    return passage[cut:end].strip()


# --- source fetching ---------------------------------------------------------

class TextExtractor(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts, self.skip = [], 0

    def handle_starttag(self, tag, attrs):
        if tag in ('script', 'style', 'nav', 'header', 'footer', 'noscript'):
            self.skip += 1

    def handle_endtag(self, tag):
        if tag in ('script', 'style', 'nav', 'header', 'footer', 'noscript') and self.skip:
            self.skip -= 1

    def handle_data(self, data):
        if not self.skip and data.strip():
            self.parts.append(data.strip())


def fetch_source(url):
    os.makedirs(SOURCE_CACHE, exist_ok=True)
    path = os.path.join(SOURCE_CACHE, hashlib.sha256(url.encode()).hexdigest()[:32] + '.json')
    if os.path.exists(path):
        with open(path) as f:
            return json.load(f)
    result = {'url': url}
    try:
        if 'web.archive.org' in url:  # the Wayback Machine rate-limits hard
            global LAST_WAYBACK
            time.sleep(max(0, LAST_WAYBACK + WAYBACK_SPACING - time.time()))
            LAST_WAYBACK = time.time()
        timeout = 90 if 'web.archive.org' in url else 25
        response = requests.get(url, headers={'User-Agent': USER_AGENT}, timeout=timeout, allow_redirects=True)
        result['http_status'] = response.status_code
        ctype = response.headers.get('content-type', '')
        if response.status_code != 200:
            result['status'] = 'http_error'
        elif 'pdf' in ctype or url.lower().endswith('.pdf'):
            with tempfile.NamedTemporaryFile(suffix='.pdf') as tmp:
                tmp.write(response.content)
                tmp.flush()
                text = subprocess.run(['pdftotext', '-q', tmp.name, '-'], capture_output=True,
                                      text=True, timeout=60).stdout
            result.update(status='ok' if len(text) > 500 else 'no_text', kind='pdf', text=text[:400000])
        else:
            parser = TextExtractor()
            parser.feed(response.text)
            text = html.unescape(' '.join(parser.parts))
            result.update(status='ok' if len(text) > 500 else 'no_text', kind='html', text=text[:400000])
    except Exception as error:  # network errors of every kind; not cached, so retried next run
        result.update(status='fetch_error', error=type(error).__name__)
        return result
    with open(path, 'w') as f:
        json.dump(result, f)
    return result


def best_excerpt(text, sentence):
    words = {w for w in WORD_RE.findall(sentence.lower()) if w not in STOPWORDS and len(w) > 2}
    if not words:
        return text[:EXCERPT_WINDOW * EXCERPT_WINDOWS]
    windows = []
    step = EXCERPT_WINDOW // 2
    for start in range(0, max(len(text) - step, 1), step):
        chunk = text[start:start + EXCERPT_WINDOW]
        score = len(words & set(WORD_RE.findall(chunk.lower())))
        windows.append((score, start, chunk))
    top = sorted(windows, reverse=True)[:EXCERPT_WINDOWS]
    return '\n[...]\n'.join(chunk for _, _, chunk in sorted(top, key=lambda w: w[1]))


def wayback(url, timestamp):
    """Internet Archive capture nearest to when the class cited the source. The
    /web/<timestamp>id_/ form redirects to the nearest capture's raw content
    (404 if none), which avoids the unreliable availability API."""
    return f'https://web.archive.org/web/{timestamp}id_/{url}'


SCHOLARLY_HOSTS = ('doi.org', 'jstor.org', 'sciencedirect.com', 'springer.com', 'wiley.com', 'tandfonline.com',
                   'sagepub.com', 'academic.oup.com', 'cambridge.org', 'muse.jhu.edu', 'nature.com',
                   'ncbi.nlm.nih.gov', 'pubmed', 'researchgate.net', 'journals.', 'onlinelibrary.')
DOI_RE = re.compile(r'10\.\d{4,9}/[^\s"<>|}]+')


def title_words(title):
    return {w for w in WORD_RE.findall((title or '').lower()) if w not in STOPWORDS}


def openalex_oa_url(fields):
    """Open-access full-text URL for a scholarly citation, via OpenAlex (no key).
    Looks up the DOI, or searches by title and accepts a close title match."""
    doi = fields.get('doi') or (DOI_RE.search(fields.get('url', '')) or [None])[0]
    try:
        if doi:
            response = requests.get(f'https://api.openalex.org/works/doi:{doi.rstrip(".")}', timeout=25,
                                    headers={'User-Agent': USER_AGENT})
            work = response.json() if response.status_code == 200 else None
        elif fields.get('title') and len(title_words(fields['title'])) >= 3:
            response = requests.get('https://api.openalex.org/works', timeout=25,
                                    params={'search': fields['title'], 'per_page': 1},
                                    headers={'User-Agent': USER_AGENT})
            results = response.json().get('results', []) if response.status_code == 200 else []
            work = results[0] if results else None
            if work:
                want, got = title_words(fields['title']), title_words(work.get('title'))
                if len(want & got) / max(len(want | got), 1) < 0.8:
                    work = None
        else:
            return None
    except Exception:
        return None
    if not work:
        return None
    for location in [work.get('best_oa_location')] + (work.get('oa_locations') or []):
        if location and (location.get('pdf_url') or location.get('landing_page_url')) and location.get('is_oa', True):
            return location.get('pdf_url') or location.get('landing_page_url')
    return None


def scholarly(fields):
    url = fields.get('url', '')
    return bool(fields.get('doi') or fields.get('journal') or any(h in url for h in SCHOLARLY_HOSTS))


def source_for(fields, sentence, timestamp):
    url = fields.get('url') or (f"https://doi.org/{fields['doi']}" if fields.get('doi') else None)
    if not url:
        return {'status': 'no_url'}
    result, via = {'status': 'not_tried'}, None
    if scholarly(fields):  # prefer open-access full text over landing pages
        oa_url = openalex_oa_url(fields)
        if oa_url:
            result, via = fetch_source(oa_url), 'openalex'
    if result.get('status') != 'ok':
        result, via = fetch_source(url), 'live'
    if result.get('status') != 'ok' and fields.get('archive-url'):
        result, via = fetch_source(fields['archive-url']), 'archive-url'
    if result.get('status') != 'ok':
        snapshot = wayback(url, timestamp)
        if snapshot:
            result, via = fetch_source(snapshot), 'wayback'
    out = {'status': result.get('status'), 'url': url, 'via': via}
    if result.get('status') == 'ok':
        out['excerpt'] = best_excerpt(result['text'], sentence)
    return out


def build_item(item_id, course_id, page_id, rng):
    with gzip.open(os.path.join(BUNDLES, f'{course_id}_{page_id}.json.gz')) as f:
        bundle = json.load(f)
    snaps = bundle['snapshots']
    end = snaps['end']['text'] or ''
    baseline = (snaps.get('baseline') or {}).get('text') or ''
    paras = added_paragraphs(baseline, end)
    passage, claims = passage_with_markers(paras, named_refs(end))
    if len(passage) > PASSAGE_LIMIT:
        passage = passage[:PASSAGE_LIMIT] + '\n[... passage truncated]'
    visible = [c for c in claims if f'[{c["n"]}]' in passage and c['sentence']]
    chosen = sorted(rng.sample(visible, min(MAX_CLAIMS, len(visible))), key=lambda c: c['n'])
    stamp = re.sub(r'\D', '', snaps['end']['timestamp'])[:8]
    out_claims = []
    for claim in chosen:
        fields = cite_fields(claim['ref'])
        out_claims.append({'marker': claim['n'], 'sentence': claim['sentence'],
                           'citation': {k: v for k, v in fields.items() if k != 'archive-url'},
                           'source': source_for(fields, claim['sentence'], stamp)})
    return {'item_id': item_id, 'article_title': bundle.get('title'), 'added_passage': passage,
            'cited_claims_in_passage': len(visible), 'claims': out_claims}


def main():
    per_stratum = int(sys.argv[1]) if len(sys.argv) > 1 else 13
    rng = random.Random(20260930)
    os.makedirs(OUT_DIR, exist_ok=True)
    picked = sample(per_stratum, rng)
    rng.shuffle(picked)
    with open(os.path.join(OUT_DIR, 'items.jsonl'), 'w') as items, \
         open(os.path.join(OUT_DIR, 'key.jsonl'), 'w') as key:
        for n, ((group, era), course_id, page_id) in enumerate(picked, 1):
            item_id = f'item_{n:03d}'
            item = build_item(item_id, course_id, page_id, rng)
            items.write(json.dumps(item) + '\n')
            key.write(json.dumps({'item_id': item_id, 'course_id': course_id, 'page_id': page_id,
                                  'group': group, 'era': era}) + '\n')
            statuses = [c['source']['status'] for c in item['claims']]
            print(item_id, group, era, f"passage={len(item['added_passage'])}", 'sources:', statuses, flush=True)


if __name__ == '__main__':
    main()
