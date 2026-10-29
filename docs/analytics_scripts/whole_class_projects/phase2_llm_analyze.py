"""Phase 2 of PLAN.md: summarize LLM grades of the pilot items.

Joins data/phase2_llm/grades/sonnet_*.jsonl with data/phase2_llm/key.jsonl
(group and era per item) and reports, by group x era:
  - how many claims could be checked (source text retrieved and relevant)
  - support labels among checkable claims, and source mismatches
  - per-item passage grades
Then 95% intervals for the main contrasts, resampling courses (items from the
same course move together), and Sonnet vs Opus agreement on the items both
graded (opus_*.jsonl). Set WCP_LLM_DIR to analyze another run.
"""
import collections
import glob
import json
import os
import random
import statistics

HERE = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                    os.environ.get('WCP_LLM_DIR', 'data/phase2_llm'))
BOOT = 2000
ORDINAL = {'none': 0, 'minor': 1, 'some': 1, 'major': 2, 'many': 2, 'strong': 2}
SUPPORT = ['supported', 'partially_supported', 'not_supported', 'contradicted']


def load(pattern):
    out = {}
    for path in sorted(glob.glob(os.path.join(HERE, 'grades', pattern))):
        for line in open(path):
            grade = json.loads(line)
            out[grade['item_id']] = grade
    return out


def kappa(pairs):
    labels = sorted({a for a, _ in pairs} | {b for _, b in pairs})
    n = len(pairs)
    observed = sum(a == b for a, b in pairs) / n
    ca = collections.Counter(a for a, _ in pairs)
    cb = collections.Counter(b for _, b in pairs)
    expected = sum(ca[label] * cb[label] for label in labels) / n / n
    return (observed - expected) / (1 - expected) if expected < 1 else 1.0


def item_scores(grade):
    checkable = [c for c in grade['claims'] if c['support'] != 'unverifiable']
    problem = [c for c in checkable if c['support'] in ('not_supported', 'contradicted')]
    return {
        'claims': len(grade['claims']), 'checkable': len(checkable),
        'fully_supported': sum(c['support'] == 'supported' for c in checkable),
        'problem': len(problem),
        'overall_quality': grade['overall_quality'], 'encyclopedic_tone': grade['encyclopedic_tone'],
        **{f: ORDINAL.get(grade[f], 0) for f in ('original_research', 'essay_like', 'promotional',
                                                 'unsourced_substantive', 'ai_style_prose')},
    }


def contrasts(sonnet, key):
    """Whole-class minus comparison, per era, with course-cluster bootstrap.
    Claim measures pool claims within the resampled courses."""
    rng = random.Random(20260930)
    by_course = collections.defaultdict(list)
    for item_id, grade in sonnet.items():
        k = key[item_id]
        by_course[(k['group'], k['era'], k['course_id'])].append(item_scores(grade))

    def stat(courses, measure):
        items = [s for c in courses for s in by_course[c]]
        if measure in ('fully_supported', 'problem'):
            denom = sum(s['checkable'] for s in items)
            return sum(s[measure] for s in items) / denom if denom else None
        if measure == 'checkable':
            denom = sum(s['claims'] for s in items)
            return sum(s['checkable'] for s in items) / denom if denom else None
        return statistics.fmean(s[measure] for s in items) if items else None

    measures = [('checkable', 'share of claims checkable'),
                ('fully_supported', 'fully supported, of checkable'),
                ('problem', 'not supported or contradicted, of checkable'),
                ('overall_quality', 'overall quality (1-5)'), ('encyclopedic_tone', 'tone (1-5)'),
                ('unsourced_substantive', 'unsourced substantive (0-2)'), ('essay_like', 'essay-like (0-2)'),
                ('original_research', 'original research (0-2)'), ('ai_style_prose', 'AI-style prose (0-2)')]
    print('\nWhole-class minus comparison (95% CI, courses resampled)')
    for era in ('pre2023', 'post2023'):
        wc = [c for c in by_course if c[0] == 'whole_class' and c[1] == era]
        cmp_ = [c for c in by_course if c[0] == 'comparison' and c[1] == era]
        print(f'  {era}: {len(wc)} whole-class vs {len(cmp_)} comparison courses')
        for measure, label in measures:
            point = [stat(wc, measure), stat(cmp_, measure)]
            if None in point:
                continue
            boots = []
            for _ in range(BOOT):
                a = stat(rng.choices(wc, k=len(wc)), measure)
                b = stat(rng.choices(cmp_, k=len(cmp_)), measure)
                if a is not None and b is not None:
                    boots.append(a - b)
            boots.sort()
            lo, hi = boots[int(0.025 * len(boots))], boots[int(0.975 * len(boots))]
            print(f'    {label:46s} {point[0]:6.2f} vs {point[1]:6.2f}  diff {point[0] - point[1]:+.2f} '
                  f'[{lo:+.2f}, {hi:+.2f}]')


def main():
    key = {k['item_id']: k for k in map(json.loads, open(os.path.join(HERE, 'key.jsonl')))}
    sonnet, opus = load('sonnet_*.jsonl'), load('opus_*.jsonl')
    cells = collections.defaultdict(list)
    for item_id, grade in sonnet.items():
        cells[(key[item_id]['group'], key[item_id]['era'])].append(grade)

    print(f'Sonnet-graded items: {len(sonnet)}\n')
    header = ('group', 'era', 'items', 'claims', 'checkable', 'supported', 'partial', 'not_supp',
              'contra', 'mismatch')
    print('%-12s %-9s' % header[:2] + ''.join('%10s' % h for h in header[2:]))
    for (group, era), grades in sorted(cells.items()):
        claims = [c for g in grades for c in g['claims']]
        checkable = [c for c in claims if c['support'] != 'unverifiable']
        counts = collections.Counter(c['support'] for c in checkable)
        share = (lambda label: f'{counts[label] / len(checkable):.0%}' if checkable else '-')
        print('%-12s %-9s' % (group, era) + ''.join('%10s' % v for v in (
            len(grades), len(claims), len(checkable), share('supported'), share('partially_supported'),
            share('not_supported'), share('contradicted'), sum(bool(c.get('source_mismatch')) for c in claims))))

    print('\nPassage grades (means; ordinal fields none=0, minor/some=1, major/many/strong=2)')
    fields = ['overall_quality', 'encyclopedic_tone', 'original_research', 'essay_like', 'promotional',
              'unsourced_substantive', 'ai_style_prose']
    print('%-12s %-9s' % ('group', 'era') + ''.join('%12s' % f[:11] for f in fields))
    for (group, era), grades in sorted(cells.items()):
        vals = []
        for f in fields:
            xs = [g[f] if isinstance(g[f], (int, float)) else ORDINAL.get(g[f], 0) for g in grades]
            vals.append(f'{statistics.fmean(xs):.2f}')
        print('%-12s %-9s' % (group, era) + ''.join('%12s' % v for v in vals))

    contrasts(sonnet, key)

    both = sorted(set(sonnet) & set(opus))
    if both:
        claim_pairs = [(a['support'], b['support']) for i in both
                       for a, b in zip(sonnet[i]['claims'], opus[i]['claims'])]
        print(f'\nSonnet vs Opus on {len(both)} items, {len(claim_pairs)} claims')
        print(f'  claim support: exact agreement {sum(a == b for a, b in claim_pairs) / len(claim_pairs):.0%}, '
              f'kappa {kappa(claim_pairs):.2f}')
        checkable = [(a, b) for a, b in claim_pairs if 'unverifiable' not in (a, b)]
        if checkable:
            print(f'  among claims both found checkable ({len(checkable)}): exact '
                  f'{sum(a == b for a, b in checkable) / len(checkable):.0%}')
        print(f'  disagreement types: {collections.Counter((a, b) for a, b in claim_pairs if a != b).most_common(5)}')
        for f in ('overall_quality', 'encyclopedic_tone'):
            diffs = [sonnet[i][f] - opus[i][f] for i in both]
            print(f'  {f}: within 1 point {sum(abs(d) <= 1 for d in diffs) / len(diffs):.0%}, '
                  f'mean sonnet-opus {statistics.fmean(diffs):+.2f}')
        for f in ('original_research', 'essay_like', 'ai_style_prose'):
            pairs = [(sonnet[i][f], opus[i][f]) for i in both]
            print(f'  {f}: exact {sum(a == b for a, b in pairs) / len(pairs):.0%}')


if __name__ == '__main__':
    main()
