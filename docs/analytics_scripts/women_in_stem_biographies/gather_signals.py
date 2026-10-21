"""Stage 2: gather positive-evidence signals per article.

For every title in consolidated_articles.csv, fetch from en.wikipedia.org:
  - Wikidata QID + short description (pageprops, 50/call)
  - Categories (prop=categories, 50/call, may continue)
  - Lead paragraph (prop=extracts, exintro, explaintext, 20/call)
And from wikidata.org for each resolved QID:
  - P31 (instance of), P21 (sex/gender), P106 (occupation) Q-IDs + labels
  - English description

All signals are *additive* evidence. Missing Wikidata does not exclude.
The classifier in stage 3 combines them.

Outputs (in data/):
  data/cache/qids_and_shortdescs.json   title -> {qid, short_desc}
  data/cache/categories.json            title -> [category, ...]   (sans 'Category:' prefix)
  data/cache/leads.json                 title -> lead_paragraph_text
  data/cache/wikidata_entities.json     qid -> {p31:[(qid,label)], p21:[...], p106:[...],
                                            description}

Restart-safe: each cache is loaded if present and new work is appended.
Re-running is cheap; delete a cache file to force re-fetch.
"""

import csv
import json
import os
import time
import urllib.error
import urllib.parse
import urllib.request

DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'data')
CACHE_DIR = os.path.join(DATA_DIR, 'cache')
CONSOLIDATED = os.path.join(DATA_DIR, 'consolidated_articles.csv')

WIKIPEDIA_API = 'https://en.wikipedia.org/w/api.php'
WIKIDATA_API = 'https://www.wikidata.org/w/api.php'
USER_AGENT = (
    'WikiEduWomenInSTEMAnalysis/1.0 '
    '(https://github.com/WikiEducationFoundation/WikiEduDashboard)'
)
REQUEST_DELAY = 0.05  # MediaWiki etiquette — keep <20 req/s

_last_request = 0.0


def api_get(url, params, timeout=30):
    global _last_request
    elapsed = time.time() - _last_request
    if elapsed < REQUEST_DELAY:
        time.sleep(REQUEST_DELAY - elapsed)
    query = urllib.parse.urlencode(params, doseq=True)
    req = urllib.request.Request(f'{url}?{query}', headers={'User-Agent': USER_AGENT})
    for attempt in range(4):
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
                print(f'  HTTP 429, waiting {wait}s')
                time.sleep(wait)
                continue
            if e.code >= 500:
                wait = (attempt + 1) * 3
                print(f'  HTTP {e.code}, waiting {wait}s')
                time.sleep(wait)
                continue
            raise
        except urllib.error.URLError as e:
            if attempt < 3:
                wait = (attempt + 1) * 3
                print(f'  URL error {e.reason}, retrying in {wait}s')
                time.sleep(wait)
                continue
            raise
    raise RuntimeError(f'api_get failed after retries: {url}')


def api_query(params, wiki_api=WIKIPEDIA_API):
    params = dict(params)
    params.update({'action': 'query', 'format': 'json',
                   'formatversion': '2', 'maxlag': '5'})
    return api_get(wiki_api, params)


def load_cache(name):
    path = os.path.join(CACHE_DIR, name)
    if os.path.exists(path):
        with open(path, encoding='utf-8') as f:
            return json.load(f)
    return {}


def save_cache(name, data):
    os.makedirs(CACHE_DIR, exist_ok=True)
    path = os.path.join(CACHE_DIR, name)
    tmp = path + '.tmp'
    with open(tmp, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=0)
    os.replace(tmp, path)


def read_titles():
    titles = []
    with open(CONSOLIDATED, newline='', encoding='utf-8') as f:
        for row in csv.DictReader(f):
            titles.append(row['title'])
    return titles


def _apply_chain(query, batch):
    """Build a {orig_title: canonical_title} chain through normalizations
    and redirects."""
    chain = {t: t for t in batch}
    for item in query.get('normalized', []) or []:
        for k, v in list(chain.items()):
            if v == item.get('from'):
                chain[k] = item.get('to')
    for item in query.get('redirects', []) or []:
        for k, v in list(chain.items()):
            if v == item.get('from'):
                chain[k] = item.get('to')
    return chain


def fetch_qids_and_shortdescs(titles, cache):
    todo = [t for t in titles if t not in cache]
    print(f'qids+shortdescs: {len(cache)} cached, {len(todo)} to fetch')
    for i in range(0, len(todo), 50):
        batch = todo[i:i + 50]
        data = api_query({
            'titles': '|'.join(batch),
            'prop': 'pageprops',
            'ppprop': 'wikibase_item|wikibase-shortdesc',
            'redirects': '1',
        })
        query = data.get('query', {}) or {}
        chain = _apply_chain(query, batch)
        by_canon = {}
        for page in query.get('pages', []) or []:
            title = page.get('title')
            pp = page.get('pageprops') or {}
            by_canon[title] = {
                'qid': pp.get('wikibase_item', ''),
                'short_desc': pp.get('wikibase-shortdesc', ''),
                'missing': bool(page.get('missing')),
            }
        for orig, canon in chain.items():
            entry = by_canon.get(canon, {'qid': '', 'short_desc': '', 'missing': True})
            cache[orig] = dict(entry, canonical_title=canon)
        if (i // 50) % 10 == 0:
            save_cache('qids_and_shortdescs.json', cache)
            print(f'  qids+shortdescs: {i + len(batch)}/{len(todo)}')
    save_cache('qids_and_shortdescs.json', cache)
    return cache


def fetch_categories(titles, cache):
    """Batch fetch (20 titles/call). cllimit=500 is the per-call cap, so 20
    titles × <25 cats avg keeps us comfortably under it; continuation
    handles overruns. Collects non-hidden categories only — we want the
    human-facing ones (e.g. 'American women physicists'), not maintenance
    tags. Title chain through normalizations + redirects so the per-orig
    cache key is what we started with."""
    todo = [t for t in titles if t not in cache]
    print(f'categories: {len(cache)} cached, {len(todo)} to fetch')
    for i in range(0, len(todo), 20):
        batch = todo[i:i + 20]
        accum = {t: set() for t in batch}  # canonical title -> set of cats
        chain = None
        params = {
            'titles': '|'.join(batch),
            'prop': 'categories',
            'cllimit': '500',
            'clshow': '!hidden',
            'redirects': '1',
        }
        while True:
            data = api_query(params)
            query = data.get('query', {}) or {}
            if chain is None:
                chain = _apply_chain(query, batch)
                # Seed canonical accumulators
                accum = {canon: set() for canon in set(chain.values())}
            for page in query.get('pages', []) or []:
                ptitle = page.get('title')
                if ptitle is None:
                    continue
                bucket = accum.setdefault(ptitle, set())
                for c in page.get('categories', []) or []:
                    name = c.get('title', '')
                    if name.startswith('Category:'):
                        bucket.add(name[len('Category:'):])
                    else:
                        bucket.add(name)
            cont = data.get('continue')
            if not cont:
                break
            params.update(cont)
        for orig, canon in chain.items():
            cache[orig] = sorted(accum.get(canon, set()))
        if (i // 20) % 25 == 0:
            save_cache('categories.json', cache)
            print(f'  categories: {i + len(batch)}/{len(todo)}')
    save_cache('categories.json', cache)
    return cache


def fetch_leads(titles, cache):
    todo = [t for t in titles if t not in cache]
    print(f'leads: {len(cache)} cached, {len(todo)} to fetch')
    for i in range(0, len(todo), 20):
        batch = todo[i:i + 20]
        data = api_query({
            'titles': '|'.join(batch),
            'prop': 'extracts',
            'exintro': '1',
            'explaintext': '1',
            'exsentences': '3',
            'exlimit': '20',
            'redirects': '1',
        })
        query = data.get('query', {}) or {}
        chain = _apply_chain(query, batch)
        by_canon = {}
        for page in query.get('pages', []) or []:
            if page.get('missing'):
                continue
            title = page.get('title')
            extract = (page.get('extract') or '').strip()
            if title:
                by_canon[title] = extract
        for orig, canon in chain.items():
            cache[orig] = by_canon.get(canon, '')
        if (i // 20) % 25 == 0:
            save_cache('leads.json', cache)
            print(f'  leads: {i + len(batch)}/{len(todo)}')
    save_cache('leads.json', cache)
    return cache


def fetch_wikidata_entities(qids, cache):
    """Fetch P31, P21, P106 + English description for each QID. Use
    wbgetentities with props=claims|descriptions and a language filter
    to keep payloads small. We resolve Q-value labels in a second pass."""
    todo = [q for q in qids if q and q not in cache]
    todo = sorted(set(todo))
    print(f'wikidata entities: {len(cache)} cached, {len(todo)} to fetch')

    needed_props = {'P31', 'P21', 'P106'}
    for i in range(0, len(todo), 50):
        batch = todo[i:i + 50]
        data = api_get(WIKIDATA_API, {
            'action': 'wbgetentities',
            'ids': '|'.join(batch),
            'props': 'claims|descriptions',
            'languages': 'en',
            'format': 'json',
        })
        entities = (data or {}).get('entities', {}) or {}
        for qid, ent in entities.items():
            row = {'p31': [], 'p21': [], 'p106': [], 'description': ''}
            descs = ent.get('descriptions') or {}
            en_desc = (descs.get('en') or {}).get('value', '') if isinstance(descs, dict) else ''
            row['description'] = en_desc
            claims = ent.get('claims') or {}
            for prop in needed_props:
                vals = []
                for stmt in claims.get(prop, []) or []:
                    mainsnak = stmt.get('mainsnak') or {}
                    dv = mainsnak.get('datavalue') or {}
                    val = dv.get('value') or {}
                    if isinstance(val, dict) and 'id' in val:
                        vals.append(val['id'])
                row[prop.lower()] = vals
            cache[qid] = row
        if (i // 50) % 5 == 0:
            save_cache('wikidata_entities.json', cache)
            print(f'  wd entities: {i + len(batch)}/{len(todo)}')
    save_cache('wikidata_entities.json', cache)
    return cache


def fetch_qid_labels(qid_set, cache):
    """Resolve Q-IDs (referenced from P31/P21/P106 claims) to English labels
    for human-readable judgment in stage 3. Cached separately."""
    todo = sorted([q for q in qid_set if q and q not in cache])
    print(f'qid labels: {len(cache)} cached, {len(todo)} to fetch')
    for i in range(0, len(todo), 50):
        batch = todo[i:i + 50]
        data = api_get(WIKIDATA_API, {
            'action': 'wbgetentities',
            'ids': '|'.join(batch),
            'props': 'labels',
            'languages': 'en',
            'format': 'json',
        })
        entities = (data or {}).get('entities', {}) or {}
        for qid, ent in entities.items():
            labels = ent.get('labels') or {}
            en = (labels.get('en') or {}).get('value', '') if isinstance(labels, dict) else ''
            cache[qid] = en
        if (i // 50) % 10 == 0:
            save_cache('qid_labels.json', cache)
            print(f'  qid labels: {i + len(batch)}/{len(todo)}')
    save_cache('qid_labels.json', cache)
    return cache


def main():
    titles = read_titles()
    print(f'titles: {len(titles)}')

    qd_cache = load_cache('qids_and_shortdescs.json')
    qd_cache = fetch_qids_and_shortdescs(titles, qd_cache)

    cats_cache = load_cache('categories.json')
    cats_cache = fetch_categories(titles, cats_cache)

    leads_cache = load_cache('leads.json')
    leads_cache = fetch_leads(titles, leads_cache)

    qids = sorted({v.get('qid', '') for v in qd_cache.values() if v.get('qid')})
    print(f'distinct qids: {len(qids)}')
    ent_cache = load_cache('wikidata_entities.json')
    ent_cache = fetch_wikidata_entities(qids, ent_cache)

    referenced_qids = set()
    for v in ent_cache.values():
        for prop in ('p31', 'p21', 'p106'):
            for q in v.get(prop, []) or []:
                referenced_qids.add(q)
    labels_cache = load_cache('qid_labels.json')
    labels_cache = fetch_qid_labels(referenced_qids, labels_cache)

    print('done.')


if __name__ == '__main__':
    main()
