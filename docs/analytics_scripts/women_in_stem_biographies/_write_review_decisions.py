"""One-shot: read women_bios_to_review.csv, apply Claude's tier judgments
+ excluded flags, write to_review_decided.csv. The judgments below were
made by reading each row's lead/shortdesc/p106 evidence.

Default for any unlisted title is excluded=true. Three tiers map to the
nested STEM rubrics. Notes capture WHY each inclusion was made so a
reviewer can audit.
"""

import csv
import os

DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'data')

# title -> (tier_str, note)
INCLUDES = {
    'Jessica_Murrey': (
        '1',
        'Game developer (software development = CS = Tier 1). Lead also '
        'lists peacebuilder; per rubric mixed STEM + secondary activist '
        'roles are IN when STEM occupation is listed.',
    ),
    'Josefina_Bautista_Magno': (
        '2',
        'Founder/leader of US hospice & palliative care programs; '
        'clinical-medicine-adjacent (palliative care = medical specialty). '
        'Tier 2 (medicine/health).',
    ),
    'Patti_Duncan': (
        '3',
        'Professor of Women, Gender, and Sexuality Studies (Oregon State). '
        'Gender studies / WGSS is widely placed under interdisciplinary '
        'social sciences. Tier 3 only (excluded from Tier 1+2).',
    ),
    'Sara_Bannerman': (
        '3',
        'Canada Research Chair in Communication Policy and Governance; '
        'communications studies = social science. Tier 3.',
    ),
}


def main():
    in_path = os.path.join(DATA_DIR, 'women_bios_to_review.csv')
    out_path = os.path.join(DATA_DIR, 'to_review_decided.csv')
    with open(in_path, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        rows = list(reader)
        fieldnames = list(reader.fieldnames or [])
    for extra in ('excluded', 'review_note'):
        if extra not in fieldnames:
            fieldnames.append(extra)

    for r in rows:
        t = r['title']
        if t in INCLUDES:
            tier, note = INCLUDES[t]
            r['tier'] = tier
            r['excluded'] = 'false'
            r['review_note'] = note
        else:
            r['tier'] = ''
            r['excluded'] = 'true'
            r['review_note'] = 'Claude review: not a STEM/medicine/social-sciences bio of a woman per lead + shortdesc + p106.'

    with open(out_path, 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        for r in rows:
            w.writerow(r)
    print(f'wrote {len(rows)} rows to to_review_decided.csv')
    print(f'  included: {sum(1 for r in rows if r["excluded"] == "false")} '
          f'(tier 1: {sum(1 for r in rows if r["tier"] == "1")}; '
          f'tier 2: {sum(1 for r in rows if r["tier"] == "2")}; '
          f'tier 3: {sum(1 for r in rows if r["tier"] == "3")})')


if __name__ == '__main__':
    main()
