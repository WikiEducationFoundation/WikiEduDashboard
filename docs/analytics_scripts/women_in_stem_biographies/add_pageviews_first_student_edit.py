"""Stage 4 (variant): pageviews per woman-in-STEM bio, scoped from the
*first edit by a student* on that article — the dashboard's standard
window — rather than the course-start-date proxy used by
`add_pageviews.py`.

For each row in women_bios_final.csv:
  1. Walk MediaWiki revisions for the article in ascending order, starting
     from one day before the earliest course-start date (a lower bound
     that's always ≤ any real student edit).
  2. Find the first revision whose `user` is in the article's student
     set (from consolidated_articles.csv).
  3. Use that timestamp as `pageviews_start` and fetch pageviews from
     it through today.

Writes:
  data/cache/first_student_edits.json   article -> {timestamp, user}
  data/cache/pageviews_v2/<safe>.json   per-article daily-views response
  women_bios_with_pageviews_first_edit.csv

Restart-safe: existing per-article first-edit lookups and pageviews
responses are reused.
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
CACHE_DIR = os.path.join(DATA_DIR, 'cache')
PV_CACHE_DIR = os.path.join(CACHE_DIR, 'pageviews_v2')
EDITS_CACHE = os.path.join(CACHE_DIR, 'first_student_edits.json')
INPUT_CSV = os.path.join(DATA_DIR, 'women_bios_final.csv')
OUTPUT_CSV = os.path.join(DATA_DIR, 'women_bios_with_pageviews_first_edit.csv')

WIKIPEDIA_API = 'https://en.wikipedia.org/w/api.php'
PV_BASE = 'https://wikimedia.org/api/rest_v1/metrics/pageviews/per-article'
USER_AGENT = (
    'WikiEduWomenInSTEMAnalysis/1.0 '
    '(https://github.com/WikiEducationFoundation/WikiEduDashboard)'
)
REQUEST_DELAY = 0.05  # action API floor
PV_REQUEST_DELAY = 0.10
END_DATE = dt.date.today().strftime('%Y%m%d')

_last_request = 0.0
_last_pv_request = 0.0


def api_get(url, params, timeout=30, delay=REQUEST_DELAY):
    global _last_request
    elapsed = time.time() - _last_request
    if elapsed < delay:
        time.sleep(delay - elapsed)
    query = urllib.parse.urlencode(params, doseq=True)
    req = urllib.request.Request(f'{url}?{query}', headers={'User-Agent': USER_AGENT})
    for attempt in range(5):
        try:
            _last_request = time.time()
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                retry_after = resp.headers.get('Retry-After')
                if retry_after:
                    wait = int(retry_after)
                    print(f'  rate limited, waiting {wait}s')
                    time.sleep(wait)
                return json.loads(resp.read().decode('utf-8'))
        except urllib.error.HTTPError as e:
            if e.code == 429:
                wait = int(e.headers.get('Retry-After', (attempt + 1) * 5))
                wait = max(5, min(wait, 60))
                print(f'  HTTP 429, waiting {wait}s')
                time.sleep(wait)
                continue
            if e.code >= 500:
                time.sleep((attempt + 1) * 3)
                continue
            raise
        except urllib.error.URLError as e:
            if attempt < 4:
                time.sleep((attempt + 1) * 3)
                continue
            raise
    return None


def find_first_student_edit(title, students, lower_bound_yyyymmdd):
    """Walk revisions ascending from `lower_bound_yyyymmdd`, return
    (timestamp, user) of the first revision whose user is in `students`,
    or (None, None) if not found in a sane window.

    lower_bound is a YYYYMMDD string; we convert to MediaWiki's
    YYYYMMDDHHMMSS by appending '000000'. We subtract 1 day as a safety
    margin in case a student edit landed slightly before the course
    start date as recorded by the dashboard."""
    if not students:
        return None, None
    start = lower_bound_yyyymmdd
    if not start or not start.isdigit() or len(start) != 8:
        # No lower bound — fall back to scanning from earliest article
        # revision. Cheaper to bail; the caller will see None and write
        # an explanatory status.
        return None, None
    # Subtract 1 day to be safe
    try:
        d = dt.datetime.strptime(start, '%Y%m%d').date() - dt.timedelta(days=1)
        rvstart = d.strftime('%Y%m%d') + '000000'
    except ValueError:
        return None, None

    params = {
        'action': 'query',
        'format': 'json',
        'formatversion': '2',
        'maxlag': '5',
        'titles': title,
        'prop': 'revisions',
        'rvprop': 'timestamp|user',
        'rvlimit': '500',
        'rvdir': 'newer',
        'rvstart': rvstart,
        'redirects': '1',
    }
    student_set = set(students)
    pages_scanned = 0
    while True:
        data = api_get(WIKIPEDIA_API, params)
        if not isinstance(data, dict):
            return None, None
        query = data.get('query', {}) or {}
        for page in query.get('pages', []) or []:
            for rev in page.get('revisions', []) or []:
                if rev.get('user') in student_set:
                    return rev.get('timestamp', ''), rev.get('user', '')
            pages_scanned += 1
        cont = data.get('continue')
        if not cont:
            return None, None
        if pages_scanned > 50:  # safety cap, ~25k revisions scanned
            return None, None
        params.update(cont)


def safe_filename(title):
    return urllib.parse.quote(title.replace(' ', '_'), safe='') + '.json'


def fetch_pageviews(title, start_yyyymmdd, end_yyyymmdd):
    global _last_pv_request
    elapsed = time.time() - _last_pv_request
    if elapsed < PV_REQUEST_DELAY:
        time.sleep(PV_REQUEST_DELAY - elapsed)
    encoded = urllib.parse.quote(title.replace(' ', '_'), safe='')
    url = (
        f'{PV_BASE}/en.wikipedia.org/all-access/all-agents/{encoded}/daily/'
        f'{start_yyyymmdd}/{end_yyyymmdd}'
    )
    req = urllib.request.Request(url, headers={'User-Agent': USER_AGENT})
    for attempt in range(5):
        try:
            _last_pv_request = time.time()
            with urllib.request.urlopen(req, timeout=30) as resp:
                return json.loads(resp.read().decode('utf-8'))
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return {'items': []}
            if e.code == 429:
                wait = int(e.headers.get('Retry-After', (attempt + 1) * 5))
                wait = max(5, min(wait, 60))
                print(f'  HTTP 429 on pv, waiting {wait}s ({title!r})')
                time.sleep(wait)
                continue
            if e.code >= 500:
                time.sleep((attempt + 1) * 3)
                continue
            raise
        except urllib.error.URLError:
            if attempt < 4:
                time.sleep((attempt + 1) * 3)
                continue
            raise
    return None


def load_json(path):
    if os.path.exists(path):
        with open(path, encoding='utf-8') as f:
            return json.load(f)
    return {}


def save_json(path, data):
    tmp = path + '.tmp'
    with open(tmp, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False)
    os.replace(tmp, path)


def main():
    os.makedirs(PV_CACHE_DIR, exist_ok=True)
    edits_cache = load_json(EDITS_CACHE)

    with open(INPUT_CSV, newline='', encoding='utf-8') as f:
        rows = list(csv.DictReader(f))

    # Stage A: resolve first-student-edit timestamp per article
    todo = [r for r in rows if r['title'] not in edits_cache]
    print(f'first-student-edit: {len(edits_cache)} cached, {len(todo)} to fetch')
    for i, r in enumerate(todo):
        title = r['title']
        students = [s for s in (r.get('students') or '').split('|') if s]
        lower_bound = (r.get('earliest_start_date') or '').replace('-', '')
        ts, user = find_first_student_edit(title, students, lower_bound)
        edits_cache[title] = {'timestamp': ts or '', 'user': user or ''}
        if (i + 1) % 50 == 0:
            save_json(EDITS_CACHE, edits_cache)
            print(f'  edits: {i + 1}/{len(todo)}')
    save_json(EDITS_CACHE, edits_cache)

    # Stage B: pageviews per article from each article's first-edit date
    print('fetching pageviews from first-student-edit dates...')
    out_rows = []
    for i, r in enumerate(rows):
        title = r['title']
        edit = edits_cache.get(title) or {}
        ts = edit.get('timestamp') or ''
        first_user = edit.get('user') or ''
        # Convert ISO 8601 timestamp to YYYYMMDD for the pageviews API
        start_ymd = ''
        if ts:
            try:
                start_ymd = ts[:10].replace('-', '')
            except Exception:
                start_ymd = ''
        out = dict(r)
        out['first_student_edit_ts'] = ts
        out['first_student_edit_user'] = first_user
        out['pageviews_start'] = start_ymd
        out['pageviews_end'] = END_DATE
        if not start_ymd:
            out['pageviews_since_edit'] = ''
            out['pageviews_status'] = 'no_first_edit_found'
            out_rows.append(out)
            continue
        cache_path = os.path.join(PV_CACHE_DIR, safe_filename(title))
        if os.path.exists(cache_path):
            with open(cache_path, encoding='utf-8') as f:
                data = json.load(f)
        else:
            data = fetch_pageviews(title, start_ymd, END_DATE)
            if data is None:
                out['pageviews_since_edit'] = ''
                out['pageviews_status'] = 'fetch_failed'
                out_rows.append(out)
                continue
            with open(cache_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False)
        items = data.get('items') or []
        total = sum(int(it.get('views') or 0) for it in items)
        out['pageviews_since_edit'] = total
        out['pageviews_status'] = 'ok' if items else 'no_views_in_range'
        out_rows.append(out)
        if (i + 1) % 100 == 0:
            print(f'  pageviews: {i + 1}/{len(rows)}')

    fieldnames = list(out_rows[0].keys())
    with open(OUTPUT_CSV, 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        for r in out_rows:
            w.writerow(r)
    print(f'wrote {len(out_rows)} rows to {OUTPUT_CSV}')


if __name__ == '__main__':
    main()
