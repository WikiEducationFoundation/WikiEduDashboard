"""Fetch the scored text for a stratified sample of Pangram 4.1 checks.

    python3 -I fetch_texts.py ~/pangram_preprocessing_survey

Reads pangram_checks_fall_2026.jsonl.gz from that directory, picks a sample
(per page type: up to 40 alert-level and 20 other checks, plus every alert-level
check whose student follow-up says false positive), and saves each share link's
JSON to texts/<revision_id>.json. Resumable: existing files are skipped. Pauses
between requests. The share endpoint refuses Python's default client, so it
fetches with curl.
"""
import gzip
import json
import random
import subprocess
import sys
import time
from pathlib import Path

PER_TYPE_HOT = 40
PER_TYPE_COLD = 20
PAUSE = 1.0


def is_hot(row):
    return any((w[3] or 0) > 0.9 for w in row['windows'])


def sample(rows):
    rng = random.Random(20261117)
    by_type = {}
    for r in rows:
        by_type.setdefault(r['page_type'], []).append(r)
    picked = {}
    for group in by_type.values():
        hot = [r for r in group if is_hot(r)]
        cold = [r for r in group if not is_hot(r)]
        for r in rng.sample(hot, min(PER_TYPE_HOT, len(hot))) + \
                rng.sample(cold, min(PER_TYPE_COLD, len(cold))):
            picked[r['revision_id']] = r
    for r in rows:
        fu = r.get('student_followup') or {}
        if is_hot(r) and 'false_positive' in (fu.get('AI_how_used') or []):
            picked[r['revision_id']] = r
    return list(picked.values())


def main(data_dir):
    data_dir = Path(data_dir).expanduser()
    rows = [json.loads(line) for line in
            gzip.open(data_dir / 'pangram_checks_fall_2026.jsonl.gz', 'rt')]
    rows = [r for r in rows if r['version'] == '4.1' and r['share_link']]
    chosen = sample(rows)
    out = data_dir / 'texts'
    out.mkdir(exist_ok=True)
    (data_dir / 'sample_ids.json').write_text(json.dumps([r['revision_id'] for r in chosen]))
    print(f'{len(chosen)} checks sampled')
    for i, r in enumerate(chosen):
        path = out / f"{r['revision_id']}.json"
        if path.exists():
            continue
        uuid = r['share_link'].rstrip('/').split('/')[-1]
        res = subprocess.run(['curl', '-sf', f'https://web.pangram.com/api/history/{uuid}/'],
                             capture_output=True)
        if res.returncode == 0:
            d = json.loads(res.stdout)
            path.write_text(json.dumps({'prompt': d['prompt'],
                                        'windows': d['response_payload']['windows']}))
        else:
            print(f"{r['revision_id']}: curl exit {res.returncode}")
        if i % 50 == 0:
            print(f'{i}/{len(chosen)}', flush=True)
        time.sleep(PAUSE)


if __name__ == '__main__':
    main(sys.argv[1])
