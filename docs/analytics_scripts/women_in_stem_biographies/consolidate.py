"""Stage 1: consolidate per-term campaign-article CSVs into one
per-unique-article table.

Input (in data/):
  fall_2025-campaign_articles-2026-05-19.csv
  spring_2026-campaign_articles-2026-05-19.csv
  summer_2025-campaign_articles-2026-05-19.csv

Output (in data/):
  consolidated_articles.csv  — one row per unique en.wp mainspace title,
  with student set, earliest start date, totals, and per-term presence.

Filter: namespace=0 AND wiki=en.wikipedia.org. Other namespaces (sandboxes,
user-talk, drafts) and non-English wikis are excluded — biographies live
in mainspace and the analysis is en.wp-scoped.
"""

import csv
import os
import re
from collections import defaultdict

DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'data')
TERMS = ['summer_2025', 'fall_2025', 'spring_2026']
INPUT_TEMPLATE = '{term}-campaign_articles-2026-05-19.csv'
OUTPUT = 'consolidated_articles.csv'

START_DATE_RE = re.compile(r'start=(\d{4}-\d{2}-\d{2})')


def parse_start_date(pageviews_link):
    if not pageviews_link:
        return ''
    m = START_DATE_RE.search(pageviews_link)
    return m.group(1) if m else ''


def main():
    # key: title -> aggregated dict
    agg = {}
    for term in TERMS:
        path = os.path.join(DATA_DIR, INPUT_TEMPLATE.format(term=term))
        with open(path, newline='', encoding='utf-8') as f:
            for row in csv.DictReader(f):
                if row['namespace'] != '0' or row['wiki'] != 'en.wikipedia.org':
                    continue
                title = row['title']
                rec = agg.setdefault(title, {
                    'title': title,
                    'students': set(),
                    'earliest_start': '',
                    'terms': set(),
                    'courses': set(),
                    'rows': 0,
                    'edit_count_sum': 0,
                    'characters_added_sum': 0,
                    'references_added_sum': 0,
                    'any_new': False,
                    'any_deleted': False,
                })
                rec['rows'] += 1
                rec['terms'].add(term)
                rec['courses'].add(row.get('course_slug', ''))
                for u in (row.get('usernames') or '').split(','):
                    u = u.strip()
                    if u:
                        rec['students'].add(u)
                start = parse_start_date(row.get('pageviews_link'))
                if start and (not rec['earliest_start'] or start < rec['earliest_start']):
                    rec['earliest_start'] = start
                try:
                    rec['edit_count_sum'] += int(row.get('edit_count') or 0)
                except ValueError:
                    pass
                try:
                    rec['characters_added_sum'] += int(row.get('characters_added') or 0)
                except ValueError:
                    pass
                try:
                    rec['references_added_sum'] += int(row.get('references_added') or 0)
                except ValueError:
                    pass
                if row.get('new') == 'true':
                    rec['any_new'] = True
                if row.get('deleted') == 'true':
                    rec['any_deleted'] = True

    out_path = os.path.join(DATA_DIR, OUTPUT)
    with open(out_path, 'w', newline='', encoding='utf-8') as f:
        w = csv.writer(f)
        w.writerow([
            'title', 'student_count', 'students', 'earliest_start_date',
            'terms', 'course_count', 'row_count',
            'edit_count_sum', 'characters_added_sum', 'references_added_sum',
            'any_new', 'any_deleted',
        ])
        for title in sorted(agg):
            r = agg[title]
            w.writerow([
                r['title'],
                len(r['students']),
                '|'.join(sorted(r['students'])),
                r['earliest_start'],
                '|'.join(sorted(r['terms'])),
                len(r['courses']),
                r['rows'],
                r['edit_count_sum'],
                r['characters_added_sum'],
                r['references_added_sum'],
                r['any_new'],
                r['any_deleted'],
            ])
    print(f'consolidated_articles.csv: {len(agg)} unique en.wp mainspace titles')


if __name__ == '__main__':
    main()
