"""Collect Agpedia articles as known-AI units for the detector comparison challenge set.

Agpedia (https://agpedia.org) is edited only through AI agents over MCP; every agent
revision is tagged with the client that made it (agent:claude-code, ...). Operators can
also edit directly through a web form, which leaves no agent tag, so articles with any
untagged revision are skipped. Content is CC0.

Each article yields two rows: the full article prose and its lead (the paragraphs before
the first section heading), pinned to the current revision. Text extraction mirrors
GetRevisionPlaintext for Wikipedia: tables, figures, images and citation markers are
dropped; headings, paragraphs and list items are kept. The output CSV is the input shape
for BuildAiDetectionSampleFromRows.from_csv (url, text, ground_truth, provenance, notes,
factor_* columns; everything else becomes metadata).

Usage:
    python collect_agpedia.py --out ~/detector_exemplars/agpedia_2026-10.csv
    python collect_agpedia.py --topics ~/detector_exemplars/topics_2026-10.csv \\
        --model claude-sonnet-5-5 --effort medium --out ~/detector_exemplars/agpedia_topics_2026-10-06.csv
"""

import argparse
import csv
import datetime
import re
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

from bs4 import BeautifulSoup

BASE = 'https://agpedia.org'
USER_AGENT = 'WikiEduDashboard detector research (https://github.com/WikiEducationFoundation/WikiEduDashboard)'

# Articles to leave out regardless of their history, with the reason.
EXCLUDED = {
    'suisse': 'French text under the English label',
    'markdown-how-to': 'syntax guide made mostly of code examples',
}

# Elements inside main.article that are not article prose.
NON_PROSE = [
    '.page-label-row', 'h1', 'aside', 'figure', 'img', 'pre', '.table-scroll', 'table',
    'sup.citation-ref', '#refs', '.content-language-row', '.tool-related',
]
BLOCKS = ['h2', 'h3', 'h4', 'p', 'li', 'blockquote', 'dd', 'dt']
ENGLISH_MARKERS = {'the', 'and', 'of', 'is', 'in', 'to'}

# The production minimum (CheckRevisionWithPangram::MIN_PLAIN_TEXT_LENGTH); the sample
# builder skips anything shorter.
MIN_PLAIN_TEXT_LENGTH = 500


def fetch(path, **params):
    query = urllib.parse.urlencode(params)
    request = urllib.request.Request(f'{BASE}/{path}?{query}', headers={'User-Agent': USER_AGENT})
    with urllib.request.urlopen(request, timeout=60) as response:
        return response.read().decode('utf-8')


def article_slugs():
    soup = BeautifulSoup(fetch('tool/pages', per=1000), 'html.parser')
    links = soup.select('main li a[href^="/"]')
    return [link['href'].lstrip('/') for link in links]


def revisions(soup):
    """Revision history, newest first: id, operator, agent tag and agent version."""
    revs = []
    # Page checks render in the same list markup; only revisions have compare buttons.
    for item in soup.select('ol.history-list > li:has(input[name="diffTo"])'):
        rev_id = item.select_one('input[name="diffTo"]')['value']
        meta = item.select_one('span[data-meta]')
        revs.append({
            'rev_id': rev_id,
            'operator': meta['data-user'] if meta else '',
            'agent': (meta['data-agent'] if meta else '').removeprefix('agent:'),
            'agent_version': (meta['data-agent-version'] if meta else '').removeprefix('agent_version:'),
            'date_label': meta.get_text(strip=True) if meta else '',
        })
    return revs


def prose_blocks(soup):
    """Article blocks in order as (tag, text), with non-prose elements removed."""
    article = soup.select_one('main.article')
    for selector in NON_PROSE:
        for element in article.select(selector):
            element.decompose()
    blocks = []
    for element in article.find_all(BLOCKS):
        # A list item's paragraphs are visited on their own; skip the wrapper.
        if element.name == 'li' and element.find('p'):
            continue
        text = re.sub(r'\s+', ' ', element.get_text(' ')).strip()
        text = re.sub(r'\s+([.,;:!?)])', r'\1', text)
        if text:
            blocks.append((element.name, text))
    return blocks


def is_english(text):
    words = re.findall(r"[a-z']+", text.lower())
    return bool(words) and sum(word in ENGLISH_MARKERS for word in words) / len(words) > 0.04


def collect(slug):
    """Rows for one article, or (None, reason) when it is skipped."""
    if slug in EXCLUDED:
        return None, EXCLUDED[slug]
    current = BeautifulSoup(fetch(slug, lang='en'), 'html.parser')
    revs = revisions(current)
    if not revs:
        return None, 'no revision history found'
    untagged = [rev for rev in revs if not rev['agent']]
    if untagged:
        return None, f'{len(untagged)} revision(s) without an agent tag (direct operator edit)'

    latest, first = revs[0], revs[-1]
    pinned = BeautifulSoup(fetch(slug, rev=latest['rev_id'], lang='en'), 'html.parser')
    draft = pinned.select_one('aside.article-draft-notice') is not None
    blocks = prose_blocks(pinned)
    full = '\n'.join(text for _, text in blocks)
    if not is_english(full):
        return None, 'text is not English'
    first_heading = next((i for i, (tag, _) in enumerate(blocks) if tag in ('h2', 'h3', 'h4')), len(blocks))
    lead = '\n'.join(text for _, text in blocks[:first_heading])

    shared = {
        'url': f"{BASE}/{slug}?rev={latest['rev_id']}&lang=en",
        'ground_truth': 'ai',
        'provenance': 'agpedia',
        'factor_topic': slug,
        'factor_agent': first['agent'],
        'factor_author': first['operator'],
        'agpedia_rev_id': latest['rev_id'],
        'agpedia_rev_date': latest['date_label'],
        'agpedia_created': first['date_label'],
        'agpedia_revisions': len(revs),
        'agpedia_agents': ';'.join(sorted({rev['agent'] for rev in revs})),
        'agpedia_operators': ';'.join(sorted({rev['operator'] for rev in revs})),
        'agpedia_draft': draft,
    }
    notes = (f"Agpedia article, {len(revs)} agent revision(s) by "
             f"{len({rev['operator'] for rev in revs})} operator(s); created via {first['agent']}")
    rows = [
        {**shared, 'text': full, 'factor_excerpt': 'full', 'notes': notes},
        {**shared, 'text': lead, 'factor_excerpt': 'lead', 'notes': f'{notes}; lead only'},
    ]
    return rows, None


def archive(rows, directory):
    """Keep each pinned revision's source (markdown with [@citation] keys) and rendered page (with
    its bibliography), so citations can be checked later without depending on the live site."""
    directory.mkdir(parents=True, exist_ok=True)
    for row in rows:
        if row['factor_excerpt'] != 'full':
            continue
        slug, rev = row['url'].split('?')[0].rsplit('/', 1)[-1], row['agpedia_rev_id']
        for suffix, params in (('md', {'rev': rev, 'lang': 'en', 'format': 'raw'}), ('html', {'rev': rev, 'lang': 'en'})):
            path = directory / f'{slug}-{rev}.{suffix}'
            if not path.exists():
                path.write_text(fetch(slug, **params))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--out', type=Path, required=True, help='CSV to write (keep it outside the repo)')
    parser.add_argument('--delay', type=float, default=0.5, help='seconds between articles')
    parser.add_argument('--topics', type=Path,
                        help='CSV with a topic column: collect only the articles on those topics, and use '
                             'the topic name as factor_topic so they pair with units on the same topic')
    parser.add_argument('--archive', type=Path, default=Path('~/detector_exemplars/agpedia_archive'),
                        help='where to keep the raw markdown and rendered page of each pinned revision')
    parser.add_argument('--model', help='model the articles were written with, when known (factor_model)')
    parser.add_argument('--effort', help='reasoning effort the articles were written with (factor_effort)')
    args = parser.parse_args()

    rows, skipped = [], []
    slugs = article_slugs()
    topic_for = {}
    if args.topics:
        with args.topics.expanduser().open() as handle:
            wanted = [row['topic'] for row in csv.DictReader(handle)]
        # Agpedia drops apostrophes and other punctuation from slugs (Marsy's Law is marsys-law).
        squash = lambda text: re.sub(r'[^a-z0-9]', '', text.lower())
        by_squashed = {squash(slug): slug for slug in slugs}
        topic_for = {by_squashed[squash(topic)]: topic for topic in wanted if squash(topic) in by_squashed}
        missing = [topic for topic in wanted if topic not in topic_for.values()]
        if missing:
            print(f'no Agpedia article found for: {", ".join(missing)}')
        slugs = list(topic_for)
    for slug in slugs:
        article_rows, reason = collect(slug)
        if reason:
            skipped.append((slug, reason))
        else:
            for row in article_rows:
                row['factor_topic'] = topic_for.get(slug, slug)
                if args.model:
                    row['factor_model'] = args.model
                if args.effort:
                    row['factor_effort'] = args.effort
            rows.extend(article_rows)
        time.sleep(args.delay)

    archive(rows, args.archive.expanduser())
    collected_at = datetime.date.today().isoformat()
    for row in rows:
        row['collected_at'] = collected_at
        row['words'] = len(row['text'].split())
    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open('w', newline='') as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)

    short = [row for row in rows if len(row['text']) < MIN_PLAIN_TEXT_LENGTH]
    print(f'{len(slugs)} articles listed; {len(rows) // 2} collected; {len(skipped)} skipped')
    for slug, reason in skipped:
        print(f'  skipped {slug}: {reason}')
    print(f"{len(rows)} rows written to {args.out}; {len(short)} under {MIN_PLAIN_TEXT_LENGTH} "
          'characters (the sample builder will skip them):')
    for row in short:
        print(f"  {row['factor_topic']} ({row['factor_excerpt']}, {len(row['text'])} characters)")
    words = sorted(row['words'] for row in rows if row['factor_excerpt'] == 'full')
    if words:
        print(f'full-article words: median {words[len(words) // 2]}, min {words[0]}, max {words[-1]}, '
              f'total {sum(words)}')


if __name__ == '__main__':
    sys.exit(main())
