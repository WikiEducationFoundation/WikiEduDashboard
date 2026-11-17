"""Compare ablation results with the production results for the same checks.

    python3 -I compare_ablation.py ~/pangram_preprocessing_survey

For each group (template, citation, baseline) prints how many checks stay alert-level
(any window above 0.9), the change in Pangram's AI fraction, and per-check rows.
All inputs were alert-level in production, so "cleared" means the alert would not
have fired.
"""
import gzip
import json
import statistics
import sys
from pathlib import Path

HOT = 0.9


def score(w):
    return w.get('ai_assistance_score', w.get('ai_likelihood')) or 0


def main(data_dir):
    data_dir = Path(data_dir).expanduser()
    meta = {r['revision_id']: r for r in map(json.loads, gzip.open(
        data_dir / 'pangram_checks_fall_2026.jsonl.gz', 'rt'))}
    claims = {c['rev']: c['fp_claim'] for c in
              json.loads((data_dir / 'check_summary.json').read_text())}
    results = [json.loads(p.read_text()) for p in (data_dir / 'ablation_results').glob('*.json')]
    for group in ('baseline', 'template', 'citation'):
        rows = []
        for r in results:
            i = r['input']
            if i['group'] != group:
                continue
            m = meta[i['rev']]
            orig = json.loads((data_dir / 'texts' / f"{i['rev']}.json").read_text())
            new = r['response']
            rows.append({
                'rev': i['rev'], 'pt': m['page_type'], 'claim': claims.get(i['rev']),
                'words': (len(orig['prompt'].split()), len(i['text'].split())),
                'hot': (sum(score(w) > HOT for w in orig['windows']),
                        sum(score(w) > HOT for w in new['windows'])),
                'frac': (m['fraction_ai'] or 0, new.get('fraction_ai') or 0),
                'label': (m['prediction_short'], new.get('prediction_short'))})
        if not rows:
            continue
        cleared = [r for r in rows if r['hot'][1] == 0]
        deltas = [r['frac'][1] - r['frac'][0] for r in rows]
        print(f'\n== {group}: {len(rows)} checks; {len(cleared)} no longer alert-level; '
              f'AI fraction change median {statistics.median(deltas):+.2f}, '
              f'up for {sum(d > 0.05 for d in deltas)}, down for {sum(d < -0.05 for d in deltas)}')
        claimed = [r for r in rows if r['claim']]
        if claimed:
            print(f'   with student FP claims: {len(claimed)}, cleared '
                  f'{sum(r["hot"][1] == 0 for r in claimed)}')
        for r in sorted(rows, key=lambda r: (r['hot'][1] > 0, r['frac'][1] - r['frac'][0])):
            print(f"   {r['rev']} {r['pt'][:12]:12} {'FP' if r['claim'] else '  '} "
                  f"words {r['words'][0]:4}->{r['words'][1]:4}  hot {r['hot'][0]:2}->{r['hot'][1]:2}  "
                  f"ai {r['frac'][0]:.2f}->{r['frac'][1]:.2f}  {r['label'][0]}->{r['label'][1]}")


if __name__ == '__main__':
    main(sys.argv[1])
