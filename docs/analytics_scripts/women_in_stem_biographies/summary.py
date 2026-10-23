"""Stage 5: print the headline numbers across the three tier
definitions, broken down by student-contribution size.

Reads a women_bios_with_pageviews*.csv (default course-start-date
variant; pass a path to switch) and joins in characters_added_sum
from consolidated_articles.csv. Prints, per tier and per
contribution-size bucket:
  - unique articles
  - unique students
  - pageviews-since-edit sum

Tiers are nested: an article in tier 1 is also in (1+2) and (1+2+3).
Size buckets are also nested: 'all' ⊇ '>=100 words' ⊇ '>=200 words'
⊇ ... ⊇ '>=1000 words'.

Words are derived from characters_added_sum using the same formula
as lib/word_count.rb in the dashboard codebase:
  words = int(chars / 5.175)
(Halfaker's en.wp regression: ~5.175 characters per word.)
"""

import csv
import os
import sys

DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'data')
DEFAULT_CSV = os.path.join(DATA_DIR, 'women_bios_with_pageviews.csv')
CONSOLIDATED_CSV = os.path.join(DATA_DIR, 'consolidated_articles.csv')

CHARS_PER_WORD = 5.175  # matches WordCount::HALFAK_EN_WIKI_ESTIMATE


def words_from_chars(chars):
    return int(chars / CHARS_PER_WORD)


def load_chars_by_title():
    chars = {}
    with open(CONSOLIDATED_CSV, newline='', encoding='utf-8') as f:
        for row in csv.DictReader(f):
            try:
                chars[row['title']] = int(row.get('characters_added_sum') or 0)
            except ValueError:
                chars[row['title']] = 0
    return chars


def empty_bucket():
    return {'articles': set(), 'students': set(),
            'pageviews': 0, 'pv_missing': 0}


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_CSV
    print(f'reading {path}')
    chars_by_title = load_chars_by_title()

    tiers_in_scope = {
        'Tier 1 (core STEM)': {'1'},
        'Tier 1 + medicine/health (Tiers 1+2)': {'1', '2'},
        'Tier 1 + medicine + social sciences (Tiers 1+2+3)': {'1', '2', '3'},
    }
    word_thresholds = [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000]
    buckets = ['all'] + [f'>={n} words' for n in word_thresholds]
    by_tier = {
        label: {b: empty_bucket() for b in buckets}
        for label in tiers_in_scope
    }
    missing_chars_titles = 0

    with open(path, newline='', encoding='utf-8') as f:
        for row in csv.DictReader(f):
            t = (row.get('tier') or '').strip()
            title = row['title']
            chars = chars_by_title.get(title)
            if chars is None:
                missing_chars_titles += 1
                chars = 0
            words = words_from_chars(chars)
            row_buckets = ['all']
            for n in word_thresholds:
                if words >= n:
                    row_buckets.append(f'>={n} words')

            for label, scope in tiers_in_scope.items():
                if t not in scope:
                    continue
                for b in row_buckets:
                    agg = by_tier[label][b]
                    agg['articles'].add(title)
                    for u in (row.get('students') or '').split('|'):
                        u = u.strip()
                        if u:
                            agg['students'].add(u)
                    pv = (row.get('pageviews_since_edit') or '').strip()
                    if pv.isdigit():
                        agg['pageviews'] += int(pv)
                    else:
                        agg['pv_missing'] += 1

    for label, by_bucket in by_tier.items():
        print(f'\n=== {label} ===')
        for b in buckets:
            agg = by_bucket[b]
            print(f'  -- {b} --')
            print(f'    unique articles:   {len(agg["articles"])}')
            print(f'    unique students:   {len(agg["students"])}')
            print(f'    pageviews-since-edit (sum): {agg["pageviews"]:,}')
            if agg['pv_missing']:
                print(f'    rows missing pageviews: {agg["pv_missing"]}')

    if missing_chars_titles:
        print(f'\nNote: {missing_chars_titles} row(s) had no '
              f'characters_added_sum match in consolidated_articles.csv '
              f'(treated as 0 words).')


if __name__ == '__main__':
    main()
