"""November 2026 round of the detector comparison: new models against the earlier ones on the
same core texts. Reads the table written by export_core_table.rb.

Sections follow the analysis plan (.claude/notes/detector_comparison_analysis_plan-2026-11-17.md):
  q1  Pangram 4.0 -> 4.1 on identical texts: verdicts, alert rule, windows, whole-text score.
  q3  Originality 5.0 and 5.0 Max against AI Allowance.
  q4  Every detector on the same footing: AUC, recall at fixed false-positive rates.
  q5  October conclusions re-tested.
  q6  ParaTrace v10 (scored 2026-11-19): verdicts by group, its false positives and misses.

Detection rule as on the comparison page: any verdict short of human counts. Rates carry exact
(Clopper-Pearson) 95% intervals.

Usage:
    python round_2026_11.py ~/detector_results_2026-11/core_table.csv q1
"""

import argparse
import re
import sys
from pathlib import Path

import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent))
from readout import clopper_pearson  # noqa: E402

P40, P41 = 'Pangram 4', 'Pangram 4.1'
PT = 'ParaTrace v10'
GROUPS = ['known_human', 'article_version', 'base_prompts', 'other_strategies', 'open_weight_ladder',
          'agpedia']
LABELS = ['Human', 'Mixed', 'AI']


def load(path):
    df = pd.read_csv(path, low_memory=False)
    for column in ['flagged', 'alert']:
        df[column] = df[column].map({True: True, False: False, 'true': True, 'false': False})
    return df


def rate(series):
    k, n = int(series.sum()), int(series.count())
    if n == 0:
        return '-'
    low, high = clopper_pearson(k, n)
    return f'{k}/{n} ({100 * k / n:.1f}%, {100 * low:.1f}-{100 * high:.1f})'


def paired(df, a, b):
    """One row per text scored by both detectors, with columns suffixed _a and _b."""
    left = df[df.check_type == a].set_index('unit_id')
    right = df[df.check_type == b].set_index('unit_id')
    both = left.join(right, how='inner', lsuffix='_a', rsuffix='_b')
    both['group'] = both['group_a']
    return both


def q1(df):
    both = paired(df, P40, P41)
    print(f'## Pangram 4.0 -> 4.1 on {len(both)} texts scored by both\n')
    print('### Detection (any non-human verdict), full AI label, and alert rule (a window > 0.9)\n')
    rows = []
    for group in GROUPS + ['all']:
        g = both if group == 'all' else both[both.group == group]
        rows.append({'group': group, 'n': len(g),
                     'flagged 4.0': rate(g.flagged_a), 'flagged 4.1': rate(g.flagged_b),
                     'AI label 4.0': rate(g.label_a == 'AI'), 'AI label 4.1': rate(g.label_b == 'AI'),
                     'alert 4.0': rate(g.alert_a), 'alert 4.1': rate(g.alert_b)})
    print(pd.DataFrame(rows).to_markdown(index=False))

    print('\n### Label transitions (rows 4.0, columns 4.1)\n')
    for group in GROUPS:
        g = both[both.group == group]
        table = pd.crosstab(g.label_a, g.label_b).reindex(index=LABELS, columns=LABELS, fill_value=0)
        changed = int((g.label_a != g.label_b).sum())
        print(f'**{group}** ({len(g)} texts, {changed} changed label)\n')
        print(table.to_markdown())
        print()

    print('### Alert-rule transitions\n')
    rows = []
    for group in GROUPS:
        g = both[both.group == group]
        rows.append({'group': group, 'n': len(g),
                     'new alerts (4.0 no, 4.1 yes)': int((~g.alert_a & g.alert_b).sum()),
                     'lost alerts (4.0 yes, 4.1 no)': int((g.alert_a & ~g.alert_b).sum())})
    print(pd.DataFrame(rows).to_markdown(index=False))

    print('\n### Windows and whole-text score (mean of window scores)\n')
    rows = []
    for group in GROUPS:
        g = both[both.group == group]
        rows.append({'group': group,
                     'median windows 4.0': g.window_count_a.median(),
                     'median windows 4.1': g.window_count_b.median(),
                     'texts split more under 4.1': int((g.window_count_b > g.window_count_a).sum()),
                     'mean score 4.0': round(g.mean_window_score_a.mean(), 3),
                     'mean score 4.1': round(g.mean_window_score_b.mean(), 3),
                     'median |change|': round((g.mean_window_score_b - g.mean_window_score_a).abs().median(), 4)})
    print(pd.DataFrame(rows).to_markdown(index=False))

    human = both[both.group == 'known_human']
    flagged = human[human.flagged_b | human.alert_b]
    print(f'\n### Known-human texts flagged or alerting under 4.1: {len(flagged)}\n')
    if len(flagged):
        print(flagged[['label_a', 'label_b', 'max_score_a', 'max_score_b', 'window_count_b',
                       'humanized_window_count_b', 'word_count_a']].to_markdown())


O5, O5MAX, A15, A40 = 'Originality 5.0', 'Originality 5.0 Max', 'Originality AI Allowance 15', \
    'Originality AI Allowance 40'
ORIGINALITY = [A40, A15, O5, O5MAX]


def q3(df):
    print('## Originality 5.0 and 5.0 Max against AI Allowance 15 and 40\n')
    print('### Detection (any non-human verdict) by group\n')
    rows = []
    for group in GROUPS + ['all']:
        g = df if group == 'all' else df[df.group == group]
        row = {'group': group}
        for key in ORIGINALITY:
            row[key.replace('Originality ', '')] = rate(g[g.check_type == key].flagged)
        rows.append(row)
    print(pd.DataFrame(rows).to_markdown(index=False))

    print('\n### Verdicts of 5.0 and Max (Human / Mixed / AI) by group\n')
    rows = []
    for group in GROUPS:
        g = df[df.group == group]
        row = {'group': group}
        for key in [O5, O5MAX]:
            counts = g[g.check_type == key].label.value_counts()
            row[key.replace('Originality ', '')] = ' / '.join(str(int(counts.get(label, 0))) for label in LABELS)
        rows.append(row)
    print(pd.DataFrame(rows).to_markdown(index=False))

    print('\n### Whole-text score on known-human texts (5.0: ai_assisted_percent / 100; Allowance: AI confidence)\n')
    human = df[df.group == 'known_human']
    rows = []
    for key in ORIGINALITY:
        s = human[human.check_type == key].document_score
        top = human[human.check_type == key].max_score
        rows.append({'detector': key, 'n': int(s.count()), 'median': round(s.median(), 3),
                     '99th pct': round(s.quantile(0.99), 3), 'max': round(s.max(), 3),
                     'texts with a segment > 0.9': rate(top > 0.9)})
    print(pd.DataFrame(rows).to_markdown(index=False))

    flagged = human[human.check_type.isin([O5, O5MAX]) & human.flagged]
    print(f'\n### Known-human texts flagged by 5.0 or Max: {flagged.unit_id.nunique()}\n')
    if len(flagged):
        print(flagged[['unit_id', 'check_type', 'label', 'document_score', 'max_score', 'window_count',
                       'word_count']].sort_values(['unit_id', 'check_type']).to_markdown(index=False))

    both = paired(df, O5, O5MAX)
    agree = (both.label_a == both.label_b)
    print(f'\n### 5.0 vs Max on {len(both)} texts\n')
    print(f'- same verdict: {int(agree.sum())} ({100 * agree.mean():.1f}%)')
    print(f'- whole-text score correlation: {both.document_score_a.corr(both.document_score_b):.3f}; '
          f'median |difference| {(both.document_score_a - both.document_score_b).abs().median():.3f}')
    for group in GROUPS:
        g = both[both.group == group]
        print(f'- {group}: same verdict {int((g.label_a == g.label_b).sum())}/{len(g)}; '
              f'flagged only by 5.0 {int((g.flagged_a & ~g.flagged_b).sum())}, '
              f'only by Max {int((~g.flagged_a & g.flagged_b).sum())}')

    print('\n### 5.0 against Allowance 40 where both scored\n')
    for key in [A40, A15]:
        pair = paired(df, key, O5)
        rows = []
        for group in GROUPS:
            g = pair[pair.group == group]
            if not len(g):
                continue
            rows.append({'group': group, 'n': len(g), f'flagged {key[-13:]}': int(g.flagged_a.sum()),
                         'flagged 5.0': int(g.flagged_b.sum()),
                         'only old': int((g.flagged_a & ~g.flagged_b).sum()),
                         'only 5.0': int((~g.flagged_a & g.flagged_b).sum())})
        print(pd.DataFrame(rows).to_markdown(index=False))
        print()


DETECTORS = ['Pangram 4', 'Pangram 4.1', A40, A15, O5, O5MAX, PT, 'Open Pangram EditLens Llama',
             'Open Pangram EditLens RoBERTa', 'Desklib v1.01']
AI_GROUPS = ['base_prompts', 'other_strategies', 'agpedia']
FPRS = [0.005, 0.01, 0.02]


def whole_text_score(rows):
    """Each detector's whole-text score: Pangram's mean window score (it reports no document
    score), every other detector's own document score."""
    return rows.document_score.where(rows.document_score.notna(), rows.mean_window_score)


def auc(human, ai):
    """Probability that a random AI text outscores a random human text (ties count half)."""
    scores = pd.concat([human, ai], ignore_index=True)
    ranks = scores.rank()
    ai_ranks = ranks.iloc[len(human):]
    return (ai_ranks.sum() - len(ai) * (len(ai) + 1) / 2) / (len(ai) * len(human))


def threshold_at(human, fpr):
    """Smallest threshold that flags (score > threshold) at most fpr of the human texts."""
    ordered = human.sort_values(ascending=False).reset_index(drop=True)
    return ordered.iloc[int(fpr * len(ordered))]


def q4(df):
    print('## Every detector on the same footing\n')
    print('Whole-text scores; thresholds fitted on the 578 known-human texts (in-sample). AI texts: '
          'current models (base prompts, other strategies) and Agpedia articles; the open-weight '
          'ladder is reported separately because every detector catches it.\n')
    for subset_name, common in [('every AI text each detector scored', False),
                                ('AI texts scored by every detector', True)]:
        ai = df[df.group.isin(AI_GROUPS)]
        if common:
            ids = set.intersection(*(set(ai[ai.check_type == key].unit_id) for key in DETECTORS))
            ai = ai[ai.unit_id.isin(ids)]
        print(f'### {subset_name}\n')
        rows = []
        for key in DETECTORS:
            h = whole_text_score(df[(df.group == 'known_human') & (df.check_type == key)])
            a_rows = ai[ai.check_type == key]
            a = whole_text_score(a_rows)
            if not len(a):
                continue
            row = {'detector': key, 'AI n': len(a), 'AUC': round(auc(h, a), 4),
                   'verdict recall': rate(a_rows.flagged),
                   'above every human': rate(a > h.max())}
            for fpr in FPRS:
                row[f'recall @ {100 * fpr:g}% FPR'] = f'{100 * (a > threshold_at(h, fpr)).mean():.1f}%'
            rows.append(row)
        print(pd.DataFrame(rows).to_markdown(index=False))
        print()

    print('### Recall at a 1% false-positive threshold, by group\n')
    rows = []
    for key in DETECTORS:
        h = whole_text_score(df[(df.group == 'known_human') & (df.check_type == key)])
        threshold = threshold_at(h, 0.01)
        row = {'detector': key, 'threshold': round(threshold, 4)}
        for group in AI_GROUPS + ['open_weight_ladder', 'article_version']:
            g = df[(df.group == group) & (df.check_type == key)]
            row[group] = f'{100 * (whole_text_score(g) > threshold).mean():.0f}% ({len(g)})' if len(g) else '-'
        rows.append(row)
    print(pd.DataFrame(rows).to_markdown(index=False))

    print('\n### Pairwise disagreement on AI texts scored by both (vendor verdicts)\n')
    pairs = [('Pangram 4.1', O5), ('Pangram 4.1', A40), (O5, A15), ('Pangram 4.1', 'Desklib v1.01'),
             ('Pangram 4.1', PT), (O5, PT)]
    rows = []
    for a_key, b_key in pairs:
        both = paired(df, a_key, b_key)
        both = both[both.group.isin(AI_GROUPS)]
        rows.append({'A': a_key, 'B': b_key, 'n': len(both),
                     'both flag': int((both.flagged_a & both.flagged_b).sum()),
                     'only A': int((both.flagged_a & ~both.flagged_b).sum()),
                     'only B': int((~both.flagged_a & both.flagged_b).sum()),
                     'neither': int((~both.flagged_a & ~both.flagged_b).sum())})
    print(pd.DataFrame(rows).to_markdown(index=False))


MAIN = ['Pangram 4', 'Pangram 4.1', O5, O5MAX, PT]
STRATEGIES = ['one_line', 'detailed', 'one_line_web', 'detailed_web', 'assignment', 'assignment_web',
              'chatgpt_prompt_web']
WEB_STRATEGIES = ['one_line_web', 'detailed_web', 'assignment_web', 'chatgpt_prompt_web']
MODEL_NAMES = {'gemini-3.6-flash-medium': 'gemini-3.6-flash', 'gemini-3.1-pro-high': 'gemini-3.1-pro',
               'gemini-3.1-pro-preview': 'gemini-3.1-pro'}
PERMUTATIONS = 2000


def sign_test(differences):
    """Two-sided sign test p-value; zero differences are dropped."""
    from readout import binom_cdf
    d = differences[differences != 0]
    n, k = len(d), int((d > 0).sum())
    if n == 0:
        return 1.0
    return min(1.0, 2 * min(binom_cdf(k, n, 0.5), binom_cdf(n - k, n, 0.5)))


def generated(df):
    """Current models' texts, with the whole-text score, the canonical model and web use as
    October's tools check counted it (search or fetch counts; Claude's tool steps)."""
    gen = df[df.group.isin(['base_prompts', 'other_strategies'])].copy()
    gen['score'] = whole_text_score(gen)
    gen['model'] = gen.model.replace(MODEL_NAMES)
    counts = gen.web_searches.fillna(0).astype(float) + gen.web_fetches.fillna(0).astype(float)
    steps = gen.steps_per_turn.map(lambda s: max(map(int, re.findall(r'\d+', str(s))), default=0))
    gen['used_web'] = (gen.runner == 'claude') & (steps > 1) | (gen.runner != 'claude') & (counts > 0)
    return gen


def summary_cell(rows):
    return f'{rows.score.mean():.2f} / {100 * (rows.label == "AI").mean():.0f}% / {100 * rows.flagged.mean():.0f}%'


def q5(df):
    print('## October conclusions re-tested\n')
    print('Cells: mean whole-text score / full AI label / any non-human verdict.\n')
    gen = generated(df)
    agpedia = df[df.group == 'agpedia'].assign(score=lambda x: whole_text_score(x))

    print('### (a) Prompt sophistication: current models by strategy, then Agpedia\n')
    rows = []
    for strategy in STRATEGIES + ['agpedia']:
        g = agpedia if strategy == 'agpedia' else gen[gen.condition == strategy]
        row = {'strategy': strategy, 'n': len(g[g.check_type == 'Pangram 4.1'])}
        for key in MAIN:
            row[key] = summary_cell(g[g.check_type == key])
        rows.append(row)
    print(pd.DataFrame(rows).to_markdown(index=False))
    print('\nPaired by model and topic against one_line (share scoring lower / higher; ties are neither; sign test p):\n')
    rows = []
    for strategy in STRATEGIES[1:]:
        row = {'strategy': strategy}
        for key in MAIN:
            k = gen[gen.check_type == key]
            a = k[k.condition == 'one_line'].groupby(['model', 'topic']).score.mean()
            b = k[k.condition == strategy].groupby(['model', 'topic']).score.mean()
            j = pd.concat([a.rename('a'), b.rename('b')], axis=1, join='inner')
            d = j.b - j.a
            row[key] = (f'lower {100 * (d < 0).mean():.0f}% / higher {100 * (d > 0).mean():.0f}% '
                        f'of {len(j)}, p={sign_test(d):.1g}')
        rows.append(row)
    print(pd.DataFrame(rows).to_markdown(index=False))

    print('\n### (b) Topic: spread of topic means, current models, every strategy\n')
    rng = __import__('numpy').random.default_rng(20261118)
    rows = []
    for key in MAIN:
        k = gen[gen.check_type == key].reset_index(drop=True)
        means = k.groupby('topic').score.mean()
        observed = means.var()
        strata = k.groupby(['model', 'condition']).indices.values()
        exceed = 0
        for _ in range(PERMUTATIONS):
            shuffled = k.topic.to_numpy().copy()
            for idx in strata:
                shuffled[idx] = rng.permutation(shuffled[idx])
            exceed += k.score.groupby(shuffled).mean().var() >= observed
        rows.append({'detector': key, 'lowest topic': f'{means.idxmin()} {means.min():.2f}',
                     'highest topic': f'{means.idxmax()} {means.max():.2f}',
                     'permutation p': f'{(exceed + 1) / (PERMUTATIONS + 1):.4f}'})
    print(pd.DataFrame(rows).to_markdown(index=False))
    p41 = gen[gen.check_type == 'Pangram 4.1'].groupby('topic').score.mean()
    p40 = gen[gen.check_type == 'Pangram 4'].groupby('topic').score.mean()
    o5 = gen[gen.check_type == O5].groupby('topic').score.mean()
    print(f'\nTopic-mean correlation: P4.0 vs P4.1 {p40.corr(p41):.2f}; P4.1 vs O5 {p41.corr(o5):.2f}')

    print('\n### (c) Capability: by model, every strategy\n')
    rows = []
    for model, g in gen.groupby('model'):
        row = {'model': model, 'n': len(g[g.check_type == 'Pangram 4.1'])}
        for key in MAIN:
            row[key] = summary_cell(g[g.check_type == key])
        rows.append(row)
    print(pd.DataFrame(rows).to_markdown(index=False))
    for low, high in [('gpt-5.6-luna', 'gpt-6-astra'), ('gemini-3.6-flash', 'gemini-3.1-pro'),
                      ('claude-sonnet-5-5', 'claude-fable-5-1')]:
        cells = []
        for key in MAIN:
            k = gen[gen.check_type == key]
            a = k[k.model == low].groupby(['condition', 'topic']).score.mean()
            b = k[k.model == high].groupby(['condition', 'topic']).score.mean()
            j = pd.concat([a.rename('a'), b.rename('b')], axis=1, join='inner')
            cells.append(f'{key}: {j.a.mean():.2f} -> {j.b.mean():.2f} (p={sign_test(j.b - j.a):.1g})')
        print(f'- {low} -> {high}, paired on strategy and topic: ' + '; '.join(cells))

    print('\n### (d) Tools: web strategies, by whether the run used the web\n')
    web = gen[gen.condition.isin(WEB_STRATEGIES)]
    rows = []
    for used in [True, False]:
        g = web[web.used_web == used]
        row = {'used web': used, 'n': len(g[g.check_type == 'Pangram 4.1'])}
        for key in MAIN:
            row[key] = summary_cell(g[g.check_type == key])
        rows.append(row)
    print(pd.DataFrame(rows).to_markdown(index=False))

    print('\n### (e, f) Verdict recall by group: Pangram, Originality, Open Pangram\n')
    rows = []
    for group in ['base_prompts', 'other_strategies', 'open_weight_ladder', 'agpedia']:
        g = df[df.group == group]
        row = {'group': group}
        for key in ['Pangram 4', 'Pangram 4.1', A40, O5, PT, 'Open Pangram EditLens Llama',
                    'Open Pangram EditLens RoBERTa']:
            k = g[g.check_type == key]
            row[key.replace('Open Pangram EditLens', 'OP').replace('Originality ', '')] = \
                f'{100 * k.flagged.mean():.0f}% ({len(k)})' if len(k) else '-'
        rows.append(row)
    print(pd.DataFrame(rows).to_markdown(index=False))


# ParaTrace's strict threshold on the whole-text probability, as the API reported it on the core
# texts: one value for texts of up to three windows, another for longer ones.
PT_SHORT_WINDOWS = 3


def q6(df):
    pt = df[df.check_type == PT]
    print(f'## ParaTrace v10 on {len(pt)} core texts\n')
    print('### Verdicts by group\n')
    rows = []
    for group in GROUPS:
        g = pt[pt.group == group]
        row = {'group': group, 'n': len(g)}
        for label in LABELS:
            row[label] = int((g.label == label).sum())
        row['flagged'] = rate(g.flagged)
        rows.append(row)
    print(pd.DataFrame(rows).to_markdown(index=False))

    print('\n### Short (<= 3 windows) and long texts\n')
    rows = []
    for name, g in [('short', pt[pt.window_count <= PT_SHORT_WINDOWS]),
                    ('long', pt[pt.window_count > PT_SHORT_WINDOWS])]:
        human = g[g.group == 'known_human']
        ai = g[g.group.isin(AI_GROUPS)]
        rows.append({'texts': name, 'known-human flagged': rate(human.flagged),
                     'AI recall': rate(ai.flagged),
                     'AUC (probability)': round(auc(human.document_score, ai.document_score), 4)
                     if len(human) and len(ai) else '-'})
    print(pd.DataFrame(rows).to_markdown(index=False))

    others = [P41, O5, O5MAX]
    verdicts = df[df.check_type.isin(others)].pivot(index='unit_id', columns='check_type',
                                                    values='label')
    columns = ['unit_id', 'sample_name', 'word_count', 'window_count', 'label', 'fraction_ai',
               'document_score']
    print('\n### Known-human texts ParaTrace flags, with the other vendors\' verdicts\n')
    flagged = pt[(pt.group == 'known_human') & pt.flagged][columns].join(verdicts, on='unit_id')
    print(flagged.round(3).to_markdown(index=False))

    print('\n### AI texts ParaTrace calls human\n')
    missed = pt[pt.group.isin(AI_GROUPS + ['open_weight_ladder']) & ~pt.flagged]
    missed = missed[columns[:1] + ['group', 'model', 'condition', 'word_count', 'document_score']]
    print(missed.join(verdicts, on='unit_id').round(3).to_markdown(index=False))

    print('\n### AI texts Pangram 4.1 or Originality 5.0 call human\n')
    ai_ids = set(df[df.group.isin(AI_GROUPS)].unit_id)
    rows = []
    for key in [P41, O5]:
        k = df[(df.check_type == key) & df.unit_id.isin(ai_ids) & ~df.flagged]
        caught = pt[pt.unit_id.isin(k.unit_id)]
        rows.append({'detector': key, 'misses': len(k), 'ParaTrace flags': rate(caught.flagged)})
    print(pd.DataFrame(rows).to_markdown(index=False))


SECTIONS = {'q1': q1, 'q3': q3, 'q4': q4, 'q5': q5, 'q6': q6}


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('table', type=Path)
    parser.add_argument('sections', nargs='*', default=list(SECTIONS))
    args = parser.parse_args()
    df = load(args.table.expanduser())
    for name in args.sections:
        SECTIONS[name](df)
        print()


if __name__ == '__main__':
    sys.exit(main())
