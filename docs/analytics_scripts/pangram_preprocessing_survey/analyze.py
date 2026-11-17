"""Classify the lines of sampled Pangram texts and relate them to hot windows.

    python3 -I analyze.py ~/pangram_preprocessing_survey

Each non-blank line of a scored text gets one kind (see classify). A window is hot
above 0.9, the alert threshold. Prints, by page type, how much text each kind
makes up and how often it sits in hot windows; how many alert-level checks have
only non-prose-dominated hot windows; and lines repeated across many checks
(likely template or preload text).
"""
import collections
import gzip
import json
import re
import sys
from pathlib import Path

HOT = 0.9

URL = re.compile(r'https?://\S+|doi\.org/|\bdoi:|\bISBN\b', re.I)
SIGNATURE = re.compile(r'\(talk\)\s*\d{1,2}:\d{2}, \d{1,2} \w+ \d{4} \(UTC\)')
# "Surname, Given." / "Surname, G." / "Surname, Given, and Other." at line start
AUTHOR_START = re.compile(r"^[A-Z][\w'’.-]+(?: [A-Z][\w'’.-]+)?, (?:[A-Z][\w'’.-]*\.?\s?)+[,.(]")
# "A. Bansal, M. Vo, ..." / "J. Smith and ..."
INITIALS_START = re.compile(r"^(?:[A-Z]\. ?)+[A-Z][\w'’-]+(?:,| and | &)")
# Cite-template output without authors: "Title". Work. Date. Retrieved ...
QUOTED_TITLE_START = re.compile(r'^["“][^"”]{3,}["”]\s*[.,(]')
YEAR = re.compile(r'\((?:19|20)\d{2}[a-z]?\)|\b(?:19|20)\d{2}\b')
PUBLISHER = re.compile(r'University Press|Press,|Publishing|Publishers|Routledge|Springer|'
                       r'Elsevier|Wiley|Retrieved|Accessed|Journal of|pp\. \d|vol\. \d', re.I)
# Rendered citation errors/maintenance messages and DiscussionTools talk-page headers.
CS1_MESSAGE = re.compile(r'^\{\{cite \w+\}\}: |^CS1 maint:', re.I)
DISCUSSION_HEADER = re.compile(r'^Latest comment: ')
SENTENCE_END = re.compile(r'[.!?]["”’)]*$')


def normalize(line):
    return re.sub(r'\s+', ' ', line.strip().lower())


def classify(line, boilerplate=frozenset()):
    s = line.strip()
    words = len(s.split())
    if normalize(s) in boilerplate:
        return 'template'
    if CS1_MESSAGE.match(s) or DISCUSSION_HEADER.match(s):
        return 'wiki_ui'
    sig = SIGNATURE.search(s)
    if sig:
        # A comment that ends with a signature is prose; only a bare signature is non-prose.
        return 'signature' if len(s[:sig.start()].split()) < 4 else 'signed_prose'
    if URL.fullmatch(s) or (URL.search(s) and words <= 3):
        return 'url'
    # A reference starts with its authors (or has a URL) and carries a year or
    # publication details. Prose that cites "(Brown 1968, pp. 203)" starts otherwise.
    starts_like_ref = AUTHOR_START.match(s) or INITIALS_START.match(s) or QUOTED_TITLE_START.match(s)
    details = YEAR.search(s) or PUBLISHER.search(s)
    if (starts_like_ref and (details or URL.search(s))) or (URL.search(s) and YEAR.search(s)):
        return 'citation'
    if s.endswith(':') and words <= 8:
        return 'label'
    if words <= 8 and not SENTENCE_END.search(s):
        return 'heading_or_fragment'
    if words < 4:
        return 'short_line'
    return 'prose'


def lines_with_offsets(text):
    pos = 0
    for raw in text.split('\n'):
        if raw.strip():
            yield pos, pos + len(raw), raw
        pos += len(raw) + 1


def score(w):
    return w.get('ai_assistance_score', w.get('ai_likelihood')) or 0


def main(data_dir):
    data_dir = Path(data_dir).expanduser()
    meta = {r['revision_id']: r for r in map(json.loads, gzip.open(
        data_dir / 'pangram_checks_fall_2026.jsonl.gz', 'rt'))}
    texts = {}
    for path in (data_dir / 'texts').glob('*.json'):
        texts[int(path.stem)] = json.loads(path.read_text())
    print(f'{len(texts)} texts')
    template_lines = json.loads((data_dir / 'template_lines.json').read_text())
    boilerplate = {normalize(l) for ls in template_lines.values() for l in ls
                   if len(l.split()) >= 2}
    owners = collections.defaultdict(set)
    for rev, t in texts.items():
        owner = (meta[rev]['title'] or '').split('/')[0]
        for _a, _b, raw in lines_with_offsets(t['prompt']):
            owners[normalize(raw)].add(owner)
    repeated = {line for line, who in owners.items() if len(who) >= 5}
    print(f'boilerplate: {len(boilerplate)} rendered template lines, '
          f'{len(repeated - boilerplate)} more lines repeated across 5+ users')
    boilerplate |= repeated
    (data_dir / 'repeated_lines.json').write_text(json.dumps(sorted(repeated)))

    words = collections.defaultdict(collections.Counter)      # page_type -> kind -> words
    hot_words = collections.defaultdict(collections.Counter)  # words of each kind in hot windows
    checks = []
    for rev, t in texts.items():
        m = meta[rev]
        pt = m['page_type']
        text, windows = t['prompt'], t['windows']
        lines = [(a, b, raw, classify(raw, boilerplate))
                 for a, b, raw in lines_with_offsets(text)]
        for a, b, raw, kind in lines:
            n = len(raw.split())
            words[pt][kind] += n
            if any(score(w) > HOT and w['start_index'] < b and w['end_index'] > a for w in windows):
                hot_words[pt][kind] += n
        hot = [w for w in windows if score(w) > HOT]
        # A hot window is non-prose-dominated when most of its characters are non-prose lines.
        def prose_share(w):
            span = 0
            prose = 0
            for a, b, _raw, kind in lines:
                overlap = max(0, min(b, w['end_index']) - max(a, w['start_index']))
                span += overlap
                prose += overlap if kind in ('prose', 'signed_prose') else 0
            return prose / span if span else 0
        fu = (m.get('student_followup') or {}).get('AI_how_used') or []
        checks.append({'rev': rev, 'pt': pt, 'hot': len(hot),
                       'nonprose_hot': sum(prose_share(w) < 0.5 for w in hot),
                       'template_hot': sum(any(k == 'template' and w['start_index'] < b and
                                               w['end_index'] > a for a, b, _r, k in lines)
                                           for w in hot),
                       'short_hot': sum((w.get('word_count') or 0) < 15 for w in hot),
                       'fp_claim': 'false_positive' in fu,
                       'kinds': collections.Counter(k for *_x, k in lines)})

    kinds = ['prose', 'signed_prose', 'template', 'wiki_ui', 'citation', 'url', 'label', 'heading_or_fragment', 'short_line', 'signature']
    print('\n== Share of words by kind (and share of that kind\'s words inside hot windows)')
    print(f"{'page type':20}" + ''.join(f'{k[:11]:>16}' for k in kinds))
    for pt in sorted(words, key=lambda p: -sum(words[p].values())):
        total = sum(words[pt].values())
        cells = []
        for k in kinds:
            n = words[pt][k]
            cells.append(f'{n / total:6.0%} ({hot_words[pt][k] / n if n else 0:3.0%})')
        print(f'{pt:20}' + ''.join(f'{c:>16}' for c in cells))

    print('\n== Alert-level checks: all hot windows non-prose-dominated / all hot windows < 15 words')
    by_pt = collections.defaultdict(lambda: [0, 0, 0, 0, 0])
    for c in checks:
        if not c['hot']:
            continue
        row = by_pt[c['pt']]
        row[0] += 1
        row[1] += c['nonprose_hot'] == c['hot']
        row[2] += c['short_hot'] == c['hot']
        row[3] += c['fp_claim']
        row[4] += c['fp_claim'] and c['nonprose_hot'] == c['hot']
    print(f"{'page type':20}{'alert-level':>12}{'all non-prose':>15}{'all short':>11}"
          f"{'FP claimed':>12}{'FP & non-prose':>16}")
    for pt, (n, np_, sh, fp, fpnp) in sorted(by_pt.items(), key=lambda x: -x[1][0]):
        print(f'{pt:20}{n:12}{np_:15}{sh:11}{fp:12}{fpnp:16}')

    print('\n== Alert-level checks with any / all hot windows touching template text')
    for pt in sorted(by_pt, key=lambda p: -by_pt[p][0]):
        group = [c for c in checks if c['pt'] == pt and c['hot']]
        any_t = sum(c['template_hot'] > 0 for c in group)
        all_t = sum(c['template_hot'] == c['hot'] for c in group)
        fp_t = sum(c['fp_claim'] and c['template_hot'] > 0 for c in group)
        print(f'{pt:20}{len(group):5} checks  any: {any_t:4}  all: {all_t:4}  FP-claimed with any: {fp_t:3}')

    out = data_dir / 'check_summary.json'
    out.write_text(json.dumps([{**c, 'kinds': dict(c['kinds'])} for c in checks]))
    print(f'\nPer-check summary: {out}')


if __name__ == '__main__':
    main(sys.argv[1])
