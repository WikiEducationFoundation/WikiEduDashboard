"""Phase 3 of PLAN.md: compare quality signals across collaboration modes.

Aggregates wcp_analysis.phase2_article_metrics to one row per course
(article values weighted by words added; counts normalized per 1,000 words
added), then reports:

  1. Means by group — whole-class cohort (core tiers A+B, and with tier C)
     vs matched individual and small-group comparison courses — with 95%
     course-level bootstrap intervals.
  2. Within-instructor differences: each whole-class course minus the mean of
     the same instructor's individual/small-group courses.
  3. Era split: the whole-class minus comparison gap before 2023 and from 2023
     (the post-ChatGPT period), and the change in that gap.

Only pages where enrolled students added at least half the in-window bytes
count (class_byte_share >= 0.5), unless --all-pages is passed.
Writes data/phase3_course_outcomes.csv.
"""
import collections
import csv
import os
import random
import statistics
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT_CSV = os.path.join(HERE, 'data/phase3_course_outcomes.csv')
DB = ['mysql', '--no-defaults', '-u', 'wiki', '-pwikiedu', '-h', '127.0.0.1', '--batch', 'wcp_analysis']
BOOT = 2000
MIN_WORDS = 100

OUTCOMES = [
    ('survival_f180', 'share of added text surviving 180 days', 'higher'),
    ('survival_now', 'share of added text surviving to today', 'higher'),
    ('reverted_share', 'share of student revisions reverted within 30 days', 'lower'),
    ('reverted_by_other_share', 'share of student revisions reverted by outsiders', 'lower'),
    ('refs_per_kword', 'references added per 1,000 words added', 'higher'),
    ('inline_tags_after_per_kword', 'inline problem tags added after the term, per 1,000 words', 'lower'),
    ('banner_tags_after_per_kword', 'cleanup banners added after the term, per 1,000 words', 'lower'),
    ('quality_delta', 'LiftWing quality change (Stub=0..FA=5)', 'higher'),
    ('deleted_share', 'share of pages since deleted or redirected', 'lower'),
]


def query(sql):
    out = subprocess.run(DB + ['-e', sql], capture_output=True, text=True, check=True).stdout.splitlines()
    header = out[0].split('\t')
    return [dict(zip(header, [None if v == 'NULL' else v for v in line.split('\t')])) for line in out[1:]]


def num(value):
    return None if value is None else float(value)


def course_outcomes(all_pages):
    pages = query('SELECT * FROM phase2_article_metrics')
    by_course = collections.defaultdict(list)
    for p in pages:
        share = num(p['class_byte_share'])
        if not all_pages and p['deleted'] == '0' and (share is None or share < 0.5):
            continue
        by_course[int(p['course_id'])].append(p)
    rows = {}
    for cid, ps in by_course.items():
        live = [p for p in ps if p['deleted'] == '0']
        words = sum(num(p['words_added']) or 0 for p in live)
        if words < MIN_WORDS:
            continue

        def weighted(field):
            pairs = [(num(p[field]), num(p['words_added']) or 0) for p in live if p[field] is not None]
            total = sum(w for _, w in pairs)
            return sum(v * w for v, w in pairs) / total if total else None

        def per_kword(field):
            vals = [(num(p[field]), num(p['words_added']) or 0) for p in live if p[field] is not None]
            total = sum(w for _, w in vals)
            return 1000 * sum(v for v, _ in vals) / total if total else None

        revs = sum(num(p['student_revs']) or 0 for p in live)
        rows[cid] = {
            'course_id': cid, 'pages': len(ps), 'words_added': int(words),
            'survival_f180': weighted('survival_f180'), 'survival_now': weighted('survival_now'),
            'reverted_share': sum(num(p['student_revs_reverted']) or 0 for p in live) / revs if revs else None,
            'reverted_by_other_share': sum(num(p['reverted_by_other']) or 0 for p in live) / revs if revs else None,
            'refs_per_kword': per_kword('refs_added'),
            'inline_tags_after_per_kword': per_kword('inline_tags_added_after'),
            'banner_tags_after_per_kword': per_kword('banner_tags_added_after'),
            'quality_delta': weighted('quality_delta'),
            'deleted_share': sum(p['deleted'] == '1' or p['redirected'] == '1' for p in ps) / len(ps),
        }
    return rows


def boot_mean(values, rng):
    values = [v for v in values if v is not None]
    if len(values) < 3:
        return None
    means = sorted(statistics.fmean(rng.choices(values, k=len(values))) for _ in range(BOOT))
    return statistics.fmean(values), means[int(0.025 * BOOT)], means[int(0.975 * BOOT)], len(values)


def fmt(result, digits=3):
    if result is None:
        return 'n<3'
    mean, lo, hi, n = result
    return f'{mean:.{digits}f} [{lo:.{digits}f}, {hi:.{digits}f}] n={n}'


def main():
    rng = random.Random(20260929)
    all_pages = '--all-pages' in sys.argv
    outcomes = course_outcomes(all_pages)
    design = query('SELECT s.course_id, s.role, s.anchor_course_id, s.tier, s.mode, YEAR(c.start) AS year '
                   'FROM comparison_set s JOIN wcp_sanitized.courses c ON c.id = s.course_id')
    year = {int(d['course_id']): int(d['year']) for d in design}
    tier = {int(d['course_id']): d['tier'] for d in design if d['role'] == 'cohort'}
    matched = collections.defaultdict(set)
    same_instr = collections.defaultdict(set)
    for d in design:
        target = {'matched': matched, 'same_instructor': same_instr}.get(d['role'])
        if target is not None:
            target[d['mode']].add(int(d['course_id']))
            target[('anchor', int(d['anchor_course_id']))].add(int(d['course_id']))

    with open(OUT_CSV, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=['course_id', 'tier', 'year', 'pages', 'words_added']
                                + [o[0] for o in OUTCOMES])
        writer.writeheader()
        for cid, row in sorted(outcomes.items()):
            writer.writerow({**row, 'tier': tier.get(cid, ''), 'year': year.get(cid, '')})

    core = {c for c, t in tier.items() if t in ('A_confirmed', 'B_history_only') and c in outcomes}
    with_c = {c for c in tier if c in outcomes}
    groups = [('whole-class core (A+B)', core), ('whole-class A+B+C', with_c),
              ('matched individual', matched['individual'] & set(outcomes)),
              ('matched small group', matched['small_group'] & set(outcomes))]
    print(f"Pages: {'all' if all_pages else 'class_byte_share >= 0.5'}; courses with outcomes: {len(outcomes)}\n")
    print('== 1. Means by group (95% bootstrap CI)')
    for field, label, better in OUTCOMES:
        print(f'\n{label} ({better} is better)')
        for name, members in groups:
            print(f'  {name:26s} {fmt(boot_mean([outcomes[c][field] for c in members], rng))}')

    print('\n== 2. Within instructor: whole-class minus same instructor\'s other courses')
    anchors = [c for c in core if same_instr[('anchor', c)] & set(outcomes)]
    print(f'   {len(anchors)} core whole-class courses with a same-instructor comparison')
    for field, label, better in OUTCOMES:
        diffs = []
        for c in anchors:
            others = [outcomes[o][field] for o in same_instr[('anchor', c)] if o in outcomes]
            others = [v for v in others if v is not None]
            if outcomes[c][field] is not None and others:
                diffs.append(outcomes[c][field] - statistics.fmean(others))
        print(f'  {label:62s} {fmt(boot_mean(diffs, rng))}')

    print('\n== 3. Era split: whole-class core minus matched comparisons (individual + small group)')
    comparison = (matched['individual'] | matched['small_group']) & set(outcomes)
    for field, label, better in OUTCOMES:
        parts = []
        for era, test in (('pre-2023', lambda y: y < 2023), ('2023+', lambda y: y >= 2023)):
            wc = [outcomes[c][field] for c in core if test(year[c]) and outcomes[c][field] is not None]
            cmp_ = [outcomes[c][field] for c in comparison if test(year[c]) and outcomes[c][field] is not None]
            if len(wc) >= 3 and len(cmp_) >= 3:
                gaps = sorted(statistics.fmean(rng.choices(wc, k=len(wc)))
                              - statistics.fmean(rng.choices(cmp_, k=len(cmp_))) for _ in range(BOOT))
                gap = statistics.fmean(wc) - statistics.fmean(cmp_)
                parts.append(f'{era}: {gap:+.3f} [{gaps[int(.025 * BOOT)]:+.3f}, {gaps[int(.975 * BOOT)]:+.3f}] '
                             f'(n={len(wc)} vs {len(cmp_)})')
            else:
                parts.append(f'{era}: n too small')
        print(f'  {label}\n     ' + '\n     '.join(parts))
    print(f'\nWrote {OUT_CSV}')


if __name__ == '__main__':
    main()
