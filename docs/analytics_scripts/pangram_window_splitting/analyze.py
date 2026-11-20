"""Summarizes the Pangram window-splitting studies (see README.md).

Run with: python3 -I analyze.py <path to this directory's data/>
Reads the study inputs and data/results/, prints the tables the README describes.
"""
import collections
import json
import os
import statistics
import sys

DATA = sys.argv[1]
ALERT = 0.9  # CheckRevisionWithPangram alerts when any window scores above this


def load_inputs(name):
    path = os.path.join(DATA, f'{name}_inputs.jsonl')
    if not os.path.exists(path):
        return []
    return [json.loads(line) for line in open(path) if line.strip()]


def result(row_id):
    path = os.path.join(DATA, 'results', f'{row_id}.json')
    return json.load(open(path))['response'] if os.path.exists(path) else None


def summary(resp):
    windows = resp.get('windows') or []
    scores = [w['ai_assistance_score'] for w in windows]
    return {
        'version': resp.get('version'),
        'label': resp.get('prediction_short') or resp.get('headline'),
        'windows': len(windows),
        'max': max(scores) if scores else 0.0,
        'alert': bool(scores) and max(scores) > ALERT,
        'humanized': sum(1 for w in windows if w.get('is_humanized')),
        'min_words': min((w.get('word_count') or 0) for w in windows) if windows else 0,
        'fraction_ai': resp.get('fraction_ai') or 0.0,
    }


def pct(k, n):
    return f'{k}/{n} ({k / n:.0%})' if n else '0/0'


def norm(text):
    return ' '.join((text or '').split())


def windows_by_text(resp):
    return {norm(w.get('text')): w for w in resp.get('windows') or [] if w.get('text')}


def study1():
    rows = load_inputs('study1')
    print('\n=== Study 1: same texts, Pangram 4.0 (stored) vs 4.1 (today) ===')
    by_group = collections.defaultdict(list)
    for row in rows:
        new = result(row['id'])
        if new:
            by_group[row['group']].append((summary(row['v40']), summary(new), row))
    for group, pairs in by_group.items():
        n = len(pairs)
        print(f'\n{group} (n={n})')
        for tag, idx in (('4.0', 0), ('4.1', 1)):
            s = [p[idx] for p in pairs]
            labels = collections.Counter(x['label'] for x in s)
            print(f'  {tag}: labels {dict(labels)}; split {pct(sum(x["windows"] > 1 for x in s), n)}; '
                  f'would alert {pct(sum(x["alert"] for x in s), n)}; '
                  f'any humanized window {pct(sum(x["humanized"] > 0 for x in s), n)}; '
                  f'median windows {statistics.median(x["windows"] for x in s)}')
        moves = collections.Counter((a['label'], b['label']) for a, b, _ in pairs if a['label'] != b['label'])
        print(f'  label changes 4.0 -> 4.1: {dict(moves) or "none"}')
        for a, b, row in pairs:
            if row['group'] == 'human' and b['alert']:
                print(f'    HUMAN ALERT on 4.1: unit {row["unit_id"]} {row["words"]}w '
                      f'windows={b["windows"]} max={b["max"]:.2f} humanized={b["humanized"]}')


def compare_variants(rows, title):
    """Each non-original row against its original (study 2 originals live in study 1)."""
    originals = {}
    for row in load_inputs('study1') + rows:
        if row['variant'] == 'original':
            originals[row.get('unit_id') or row.get('rev_id')] = row
    stats = collections.defaultdict(lambda: collections.Counter())
    span_deltas = []
    for row in rows:
        if row['variant'] == 'original':
            continue
        key = row.get('unit_id') or row.get('rev_id')
        base_row = originals.get(key)
        base, new = result(base_row['id']) if base_row else None, result(row['id'])
        if not (base and new):
            continue
        a, b = summary(base), summary(new)
        c = stats[(row['group'], row['variant'])]
        c['n'] += 1
        c['label_flip'] += a['label'] != b['label']
        c['alert_flip'] += a['alert'] != b['alert']
        c['window_count_change'] += a['windows'] != b['windows']
        c['big_fraction_shift'] += abs(a['fraction_ai'] - b['fraction_ai']) >= 0.3
        base_windows, new_windows = windows_by_text(base), windows_by_text(new)
        for text, w in base_windows.items():
            if text in new_windows:
                delta = abs(w['ai_assistance_score'] - new_windows[text]['ai_assistance_score'])
                span_deltas.append((w.get('word_count') or 0, delta))
    print(f'\n=== {title}: each variant against its original (both scored on 4.1) ===')
    print(f'{"group":15} {"variant":16} {"n":>3}  label flips   alert flips   window-count changes   '
          f'fraction_ai moved >=0.3')
    for (group, variant), c in sorted(stats.items()):
        n = c['n']
        print(f'{group:15} {variant:16} {n:3}  {pct(c["label_flip"], n):12}  {pct(c["alert_flip"], n):12}  '
              f'{pct(c["window_count_change"], n):21}  {pct(c["big_fraction_shift"], n)}')
    if span_deltas:
        print('\n  Identical window text in original and variant: score change by window length')
        for low, high in ((0, 40), (40, 80), (80, 150), (150, 400), (400, 10**6)):
            ds = [d for words, d in span_deltas if low <= words < high]
            if ds:
                print(f'    {low:>4}-{high if high < 10**6 else "":<4} words: n={len(ds):4}  '
                      f'moved >0.5: {pct(sum(d > 0.5 for d in ds), len(ds)):14} '
                      f'median change {statistics.median(ds):.3f}')


def window_length_profile():
    """Across every 4.1 result: how extreme and how humanized windows are, by length."""
    print('\n=== All 4.1 windows: score and humanizer flag by window length ===')
    buckets = collections.defaultdict(list)
    for name in os.listdir(os.path.join(DATA, 'results')):
        resp = json.load(open(os.path.join(DATA, 'results', name)))['response']
        for w in resp.get('windows') or []:
            words = w.get('word_count') or 0
            bucket = next(b for b in (40, 80, 150, 400, 10**6) if words < b)
            buckets[bucket].append(w)
    for bucket in sorted(buckets):
        ws = buckets[bucket]
        n = len(ws)
        label = f'<{bucket}' if bucket < 10**6 else '400+'
        print(f'  {label:>5} words: n={n:5}  >0.9: {pct(sum(w["ai_assistance_score"] > ALERT for w in ws), n):14} '
              f'humanized: {pct(sum(bool(w.get("is_humanized")) for w in ws), n):14} '
              f'Low confidence: {pct(sum(w.get("confidence") == "Low" for w in ws), n)}')


def study3():
    rows = load_inputs('study3')
    print('\n=== Study 3: pre-2022 peer reviews (known human), Pangram 4.1 ===')
    by_variant = collections.defaultdict(list)
    for row in rows:
        resp = result(row['id'])
        if resp:
            by_variant[row['variant']].append((summary(resp), row))
    for variant, items in by_variant.items():
        n = len(items)
        s = [x for x, _ in items]
        print(f'  {variant:15} n={n:3}  labels {dict(collections.Counter(x["label"] for x in s))}  '
              f'would alert {pct(sum(x["alert"] for x in s), n)}  split {pct(sum(x["windows"] > 1 for x in s), n)}  '
              f'humanized {pct(sum(x["humanized"] > 0 for x in s), n)}')
        for x, row in items:
            if x['alert']:
                print(f'      ALERT: {row["title"]} rev {row["rev_id"]} windows={x["windows"]} '
                      f'max={x["max"]:.2f} humanized={x["humanized"]} min_words={x["min_words"]}')


study1()
compare_variants(load_inputs('study2'), 'Study 2: trivial edits')
compare_variants(load_inputs('study3'), 'Study 3: peer review variants')
study3()
window_length_profile()
