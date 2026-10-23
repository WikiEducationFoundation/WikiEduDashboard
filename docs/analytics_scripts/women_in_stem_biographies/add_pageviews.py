"""Stage 4: fetch pageviews per woman-in-STEM bio since its earliest
student-edit-proxy date (the earliest course-start date among courses
that touched it).

Reads:
  women_bios_final.csv   — output of (auto + reviewed) merged classification
                            with columns title, qid, tier, earliest_start_date,
                            student_count, students, terms, ...

Writes:
  data/cache/pageviews/<safe_title>.json   — raw daily-views response per article
  women_bios_with_pageviews.csv       — final annotated CSV with
                                          pageviews_since_edit column

Uses the Wikimedia REST API `metrics/pageviews/per-article` endpoint
(https://wikimedia.org/api/rest_v1/), all-access, all-agents, daily.

Restart-safe: existing per-article JSON files are reused.
"""

import csv
import datetime as dt
import json
import os
import time
import urllib.error
import urllib.parse
import urllib.request

DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'data')
PV_CACHE_DIR = os.path.join(DATA_DIR, 'cache', 'pageviews')
INPUT_CSV = os.path.join(DATA_DIR, 'women_bios_final.csv')
OUTPUT_CSV = os.path.join(DATA_DIR, 'women_bios_with_pageviews.csv')

USER_AGENT = (
    'WikiEduWomenInSTEMAnalysis/1.0 '
    '(https://github.com/WikiEducationFoundation/WikiEduDashboard)'
)
REQUEST_DELAY = 0.10  # pageviews cluster is stricter than action API
PV_BASE = 'https://wikimedia.org/api/rest_v1/metrics/pageviews/per-article'
END_DATE = dt.date.today().strftime('%Y%m%d')

_last_request = 0.0


def safe_filename(title):
    """Map a Wikipedia title to a filesystem-safe cache filename."""
    return urllib.parse.quote(title.replace(' ', '_'), safe='') + '.json'


def fetch_pageviews(title, start_yyyymmdd, end_yyyymmdd):
    global _last_request
    elapsed = time.time() - _last_request
    if elapsed < REQUEST_DELAY:
        time.sleep(REQUEST_DELAY - elapsed)
    encoded = urllib.parse.quote(title.replace(' ', '_'), safe='')
    url = (
        f'{PV_BASE}/en.wikipedia.org/all-access/all-agents/{encoded}/daily/'
        f'{start_yyyymmdd}/{end_yyyymmdd}'
    )
    req = urllib.request.Request(url, headers={'User-Agent': USER_AGENT})
    for attempt in range(5):
        try:
            _last_request = time.time()
            with urllib.request.urlopen(req, timeout=30) as resp:
                return json.loads(resp.read().decode('utf-8'))
        except urllib.error.HTTPError as e:
            if e.code == 404:
                # No pageviews recorded for this article in range
                return {'items': []}
            if e.code == 429:
                wait = int(e.headers.get('Retry-After', (attempt + 1) * 5))
                wait = max(5, min(wait, 60))
                print(f'  HTTP 429, waiting {wait}s ({title!r})')
                time.sleep(wait)
                continue
            if e.code >= 500:
                wait = (attempt + 1) * 3
                print(f'  HTTP {e.code} ({title!r}), waiting {wait}s')
                time.sleep(wait)
                continue
            raise
        except urllib.error.URLError as e:
            if attempt < 4:
                wait = (attempt + 1) * 3
                print(f'  URL err ({title!r}): {e.reason}, retry in {wait}s')
                time.sleep(wait)
                continue
            raise
    return None


def main():
    os.makedirs(PV_CACHE_DIR, exist_ok=True)
    rows_in = []
    with open(INPUT_CSV, newline='', encoding='utf-8') as f:
        rows_in = list(csv.DictReader(f))

    rows_out = []
    for i, row in enumerate(rows_in):
        title = row['title']
        start = (row.get('earliest_start_date') or '').replace('-', '')
        if not start or not start.isdigit() or len(start) != 8:
            row['pageviews_since_edit'] = ''
            row['pageviews_start'] = ''
            row['pageviews_end'] = END_DATE
            row['pageviews_status'] = 'no_start_date'
            rows_out.append(row)
            continue

        cache_path = os.path.join(PV_CACHE_DIR, safe_filename(title))
        if os.path.exists(cache_path):
            with open(cache_path, encoding='utf-8') as f:
                data = json.load(f)
        else:
            data = fetch_pageviews(title, start, END_DATE)
            if data is None:
                row['pageviews_since_edit'] = ''
                row['pageviews_start'] = start
                row['pageviews_end'] = END_DATE
                row['pageviews_status'] = 'fetch_failed'
                rows_out.append(row)
                continue
            with open(cache_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False)

        items = data.get('items') or []
        total = sum(int(it.get('views') or 0) for it in items)
        row['pageviews_since_edit'] = total
        row['pageviews_start'] = start
        row['pageviews_end'] = END_DATE
        row['pageviews_status'] = 'ok' if items else 'no_views_in_range'
        rows_out.append(row)

        if (i + 1) % 100 == 0:
            print(f'  pageviews: {i + 1}/{len(rows_in)}')

    if not rows_out:
        print('no rows.')
        return
    fieldnames = list(rows_out[0].keys())
    with open(OUTPUT_CSV, 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        for r in rows_out:
            w.writerow(r)
    print(f'wrote {len(rows_out)} rows to {OUTPUT_CSV}')


if __name__ == '__main__':
    main()
