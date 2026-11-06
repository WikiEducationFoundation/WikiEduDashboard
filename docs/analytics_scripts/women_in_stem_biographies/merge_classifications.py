"""Stage 3.5: merge auto-classified + Claude-reviewed rows into one
women_bios_final.csv.

Inputs (in data/):
  women_bios_auto.csv         — auto-decided
  to_review_decided.csv       — review CSV with Claude's filled-in
                                 `tier` column and `excluded` boolean
                                 (rows with excluded=true or empty/0 tier
                                 are dropped)

Output:
  women_bios_final.csv  — union of auto + accepted reviewed rows
"""

import csv
import os

DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'data')


def read(path):
    if not os.path.exists(path):
        return [], []
    with open(path, newline='', encoding='utf-8') as f:
        r = csv.DictReader(f)
        rows = list(r)
        return rows, r.fieldnames or []


def main():
    auto_rows, auto_fields = read(os.path.join(DATA_DIR, 'women_bios_auto.csv'))
    review_rows, review_fields = read(os.path.join(DATA_DIR, 'to_review_decided.csv'))

    fields = auto_fields[:]
    # Carry over any extra columns from the review CSV (e.g. 'excluded',
    # 'review_note') so they survive into the final output.
    for f in review_fields:
        if f not in fields:
            fields.append(f)

    kept_reviewed = []
    for r in review_rows:
        if (r.get('excluded') or '').strip().lower() in ('true', '1', 'yes'):
            continue
        tier = (r.get('tier') or '').strip()
        if tier not in ('1', '2', '3'):
            continue
        kept_reviewed.append(r)

    final = auto_rows + kept_reviewed
    final_path = os.path.join(DATA_DIR, 'women_bios_final.csv')
    with open(final_path, 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=fields, extrasaction='ignore')
        w.writeheader()
        for r in final:
            w.writerow(r)
    print(f'wrote {len(final)} rows: {len(auto_rows)} auto + '
          f'{len(kept_reviewed)} reviewed (kept) to {final_path}')


if __name__ == '__main__':
    main()
