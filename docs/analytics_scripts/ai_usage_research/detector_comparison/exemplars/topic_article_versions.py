"""Write sample rows for each challenge topic's Wikipedia article at three points in time.

For every topic in the topics CSV, whose paired_url is the cumulative diff of a student's work in
a pre-ChatGPT term:

- before_term: the article as it stood before the student's term (the diff's oldid), human.
- after_term: the article at the end of the student's term (the diff's end revision), human.
- today: the article's current revision, pinned to the id fetched now; its ground truth is left
  blank, since edits after 2022 may involve AI.

Each row's url is index.php?oldid=<rev>, which BuildAiDetectionSampleFromRows turns into a
whole-revision unit (with its wikitext as the source). The topic's current page is checked
against the after_term revision's page, so a renamed or merged article is reported rather than
paired with the wrong page.

Usage:
    python topic_article_versions.py --topics ~/detector_exemplars/topics_2026-10.csv \\
        --out ~/detector_exemplars/topic_article_versions_2026-10-12.csv
"""

import argparse
import csv
import datetime
import json
import re
import sys
import urllib.parse
import urllib.request
from pathlib import Path

API = 'https://en.wikipedia.org/w/api.php'
USER_AGENT = 'WikiEduDashboard detector research (https://github.com/WikiEducationFoundation/WikiEduDashboard)'
PRE_LLM_REVISION = 'pre_llm_revision'  # Whole-article revision from before ChatGPT
CURRENT_REVISION = 'current_revision'  # Whole-article revision as of the fetch; authorship unknown


def api(**params):
    query = urllib.parse.urlencode({'format': 'json', 'formatversion': 2, **params})
    request = urllib.request.Request(f'{API}?{query}', headers={'User-Agent': USER_AGENT})
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def revision_page(rev_id):
    page = api(action='query', prop='revisions', revids=rev_id, rvprop='ids|timestamp')['query']['pages'][0]
    return page['pageid'], page['title'], page['revisions'][0]['timestamp']


def current_revision(title):
    page = api(action='query', prop='revisions', titles=title, redirects=1, rvprop='ids|timestamp')['query']['pages'][0]
    if page.get('missing'):
        return None
    return page['pageid'], page['title'], page['revisions'][0]['revid'], page['revisions'][0]['timestamp']


def url(rev_id):
    return f'https://en.wikipedia.org/w/index.php?oldid={rev_id}'


def rows_for(topic, fetched_at):
    match = re.search(r'diff=(\d+)&oldid=(\d+)', topic['paired_url'])
    after_rev, before_rev = match.group(1), match.group(2)
    after_page, after_title, after_time = revision_page(after_rev)
    _before_page, _before_title, before_time = revision_page(before_rev)
    current = current_revision(topic['topic'])
    base = {'factor_topic': topic['topic'], 'paired_unit_id': topic['paired_unit_id'],
            'campaign_slug': topic['campaign_slug'], 'pageid': after_page, 'fetched_at': fetched_at}
    rows = [
        {**base, 'url': url(before_rev), 'factor_version': 'before_term', 'ground_truth': 'human',
         'provenance': PRE_LLM_REVISION, 'rev_timestamp': before_time,
         'notes': f'{topic["topic"]} before the student\'s {topic["campaign_slug"]} term'},
        {**base, 'url': url(after_rev), 'factor_version': 'after_term', 'ground_truth': 'human',
         'provenance': PRE_LLM_REVISION, 'rev_timestamp': after_time,
         'notes': f'{topic["topic"]} at the end of the student\'s {topic["campaign_slug"]} term ({after_title})'},
    ]
    if not current or current[0] != after_page:
        print(f'{topic["topic"]}: current page {current} is not the page of revision {after_rev} ({after_page}); no today row',
              file=sys.stderr)
        return rows
    _page, title, rev_id, rev_time = current
    if str(rev_id) == after_rev:
        print(f'{topic["topic"]}: unchanged since the term (revision {rev_id}); today is the after_term unit', file=sys.stderr)
        return rows
    rows.append({**base, 'url': url(rev_id), 'factor_version': 'today', 'ground_truth': '', 'provenance': CURRENT_REVISION,
                 'rev_timestamp': rev_time, 'notes': f'{title} as of {fetched_at[:10]}'})
    return rows


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--topics', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()

    fetched_at = datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='seconds')
    with args.topics.expanduser().open() as handle:
        topics = list(csv.DictReader(handle))
    rows = [row for topic in topics for row in rows_for(topic, fetched_at)]
    columns = ['url', 'ground_truth', 'provenance', 'notes', 'factor_topic', 'factor_version', 'campaign_slug',
               'paired_unit_id', 'pageid', 'rev_timestamp', 'fetched_at']
    with args.out.expanduser().open('w', newline='') as handle:
        writer = csv.DictWriter(handle, fieldnames=columns)
        writer.writeheader()
        writer.writerows(rows)
    print(f'{len(rows)} rows for {len(topics)} topics written to {args.out}')


if __name__ == '__main__':
    sys.exit(main())
