"""Readout of every detector on the human baseline and the known-AI challenge set.

Each detector is judged by its own verdict (Pangram's and Originality's "AI" label, Open
Pangram's top bucket), with the Dashboard's alert rule (Pangram 4 max window > 0.9) as an extra
column. Rates carry exact (Clopper-Pearson) 95% intervals. A second table calibrates a threshold
on each detector's whole-text score so that a fixed share of the baseline is flagged, then
reports recall at that threshold, and the term samples show how many units clear it per term.

The sample names are those of the October 2026 collection (README, "Exemplars and challenge
cases"); retired samples are left out.

Usage:
    python readout.py ~/detector_comparison_2026-10-12.csv \\
        --open-pangram ~/open_pangram_roberta.csv ~/open_pangram_llama.csv \\
        --markdown ~/detector_results/readout.md --json ~/detector_results/readout.json
"""

import argparse
import json
import math
from pathlib import Path

import pandas as pd

UNIT_COLUMNS = ['sample_name', 'unit_id', 'ground_truth', 'provenance', 'campaign_slug', 'word_count',
                'text_sha256', 'metadata', 'factor_model', 'factor_vendor', 'factor_era', 'factor_prompt',
                'factor_author']
SCORE_COLUMNS = ['check_type', 'label', 'max_score', 'mean_window_score', 'document_score']
ALERT_RULE = 'Pangram 4 (alert rule)'
DETECTORS = {'Pangram 4': 'P4', ALERT_RULE: 'P4 >0.9', 'Originality AI Allowance 40': 'A40',
             'Originality AI Allowance 15': 'A15', 'Open Pangram EditLens Llama': 'OP Llama',
             'Open Pangram EditLens RoBERTa': 'OP RoBERTa'}
# Whole-text score for baseline-calibrated thresholds. Pangram has no document score, so its
# length-weighted window mean stands in. Originality is left out until its baseline is scored.
WHOLE_TEXT_SCORE = {'Pangram 4': 'mean_window_score', 'Open Pangram EditLens Llama': 'document_score',
                    'Open Pangram EditLens RoBERTa': 'document_score'}
TARGET_FPRS = [0.005, 0.01, 0.02]
PARTS = [('WVS lead rewrites', 'wvs_neu'),
         ('Agpedia full articles', 'agpedia_2026_10'),
         ('Agpedia leads', 'agpedia_leads_2026_10'),
         ('Agpedia on challenge topics, full', 'agpedia_topics_2026_10'),
         ('Agpedia on challenge topics, leads', 'agpedia_topics_leads_2026_10'),
         ('Current models, base prompts', 'generated_current_2026_10'),
         ('Open-weight ladder', 'generated_ladder_2026_10'),
         ('Stratified conditions', 'generated_stratified_2026_10')]
CONDITIONS = ['one_line', 'detailed', 'one_line_250', 'one_line_1000', 'one_line_web', 'detailed_web',
              'assignment', 'assignment_web', 'assignment_apps_web', 'chatgpt_prompt_web']
TERM_SAMPLES = ['terms_2021_2025_march', 'terms_2026', 'terms_baseline_extra']
SEASONS = {'spring': 0, 'summer': 1, 'fall': 2}


def load(export_path, open_pangram_paths):
    export = pd.read_csv(export_path, low_memory=False)
    export = export[~export['sample_name'].str.endswith('_retired')]
    units = export.drop_duplicates('unit_id')[UNIT_COLUMNS]
    frames = [export[export['check_type'].isin(DETECTORS)][UNIT_COLUMNS + SCORE_COLUMNS]]
    for path in open_pangram_paths:
        scores = pd.read_csv(path)
        frames.append(units.merge(scores[['text_sha256'] + SCORE_COLUMNS], on='text_sha256'))
    df = pd.concat(frames, ignore_index=True)
    df['positive'] = df['label'] == 'AI'
    alert = df[df['check_type'] == 'Pangram 4'].assign(check_type=ALERT_RULE)
    alert['positive'] = alert['max_score'] > 0.9
    df = pd.concat([df, alert], ignore_index=True)
    df['condition'] = df['metadata'].map(lambda m: json.loads(m).get('condition') if isinstance(m, str) else None)
    df['baseline'] = (df['ground_truth'] == 'human') & (df['provenance'] == 'pre_llm_term')
    return df


def baseline(df):
    """Baseline rows, one per detector and text: some samples repeat baseline texts."""
    return df[df['baseline']].drop_duplicates(['check_type', 'text_sha256'])


def binom_cdf(k, n, p):
    if p <= 0:
        return 1.0
    if p >= 1:
        return 1.0 if k >= n else 0.0
    return min(1.0, sum(math.exp(math.lgamma(n + 1) - math.lgamma(i + 1) - math.lgamma(n - i + 1)
                                 + i * math.log(p) + (n - i) * math.log1p(-p)) for i in range(k + 1)))


def bisect(f, target, increasing):
    lo, hi = 0.0, 1.0
    for _ in range(60):
        mid = (lo + hi) / 2
        if (f(mid) < target) == increasing:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2


def clopper_pearson(k, n):
    """Exact 95% interval, by bisection on the binomial tails."""
    lower = 0.0 if k == 0 else bisect(lambda p: 1 - binom_cdf(k - 1, n, p), 0.025, increasing=True)
    upper = 1.0 if k == n else bisect(lambda p: binom_cdf(k, n, p), 0.025, increasing=False)
    return lower, upper


def rate_cell(positives):
    n = len(positives)
    if n == 0:
        return None
    k = int(positives.sum())
    lower, upper = clopper_pearson(k, n)
    return {'k': k, 'n': n, 'rate': k / n, 'lower': lower, 'upper': upper}


def rate_table(key, title, groups):
    rows = []
    for name, subset in groups:
        cells = {d: rate_cell(subset[subset['check_type'] == d]['positive']) for d in DETECTORS}
        if any(cells.values()):
            rows.append({'group': str(name), 'cells': cells})
    return {'key': key, 'title': title, 'kind': 'rates', 'rows': rows}


def by(subset, column, order=None):
    values = order or sorted(subset[column].dropna().unique())
    return [(value, subset[subset[column] == value]) for value in values if (subset[column] == value).any()]


def calibrated(df):
    """Recall per part at thresholds that flag a fixed share of the baseline."""
    rows = []
    for detector, column in WHOLE_TEXT_SCORE.items():
        base = baseline(df)
        base = base[base['check_type'] == detector][column].dropna().sort_values(ascending=False)
        if base.empty:
            continue
        for target in TARGET_FPRS:
            allowed = math.floor(target * len(base))
            threshold = float(base.iloc[allowed]) if allowed < len(base) else 0.0
            recall = {}
            for part, sample in PARTS:
                values = df[(df['sample_name'] == sample) & (df['check_type'] == detector)][column].dropna()
                recall[part] = float((values > threshold).mean()) if len(values) else None
            rows.append({'detector': detector, 'target_fpr': target, 'threshold': threshold,
                         'baseline_fpr': float((base > threshold).mean()), 'baseline_units': len(base),
                         'recall': recall})
    return {'key': 'calibrated', 'title': 'Recall at a baseline-calibrated threshold', 'kind': 'calibrated',
            'parts': [part for part, _ in PARTS], 'rows': rows}


def term_key(slug):
    season, year = str(slug).split('_')
    return int(year), SEASONS[season]


def term_trend(df, calibration):
    """Share of each term's units flagged by the verdict and above the 1%-FPR threshold."""
    thresholds = {row['detector']: row['threshold'] for row in calibration['rows'] if row['target_fpr'] == 0.01}
    terms = df[df['sample_name'].isin(TERM_SAMPLES) & df['campaign_slug'].notna()]
    rows = []
    for slug in sorted(terms['campaign_slug'].unique(), key=term_key):
        term = terms[terms['campaign_slug'] == slug]
        row = {'term': slug, 'units': int(term['unit_id'].nunique()), 'verdict': {}, 'above_threshold': {}}
        for detector, column in WHOLE_TEXT_SCORE.items():
            scored = term[term['check_type'] == detector]
            if scored.empty:
                continue
            row['verdict'][detector] = float(scored['positive'].mean())
            row['above_threshold'][detector] = float((scored[column] > thresholds[detector]).mean())
        rows.append(row)
    return {'key': 'terms', 'title': 'Term samples: verdict vs the 1%-FPR threshold', 'kind': 'terms',
            'thresholds': thresholds, 'rows': rows}


def readout(df):
    samples = df['sample_name']
    parts = [(name, df[samples == sample]) for name, sample in PARTS]
    current = df[samples == 'generated_current_2026_10']
    stratified = df[samples == 'generated_stratified_2026_10']
    calibration = calibrated(df)
    return [
        rate_table('baseline', 'Human baseline: false positives', [('Pre-ChatGPT student text', baseline(df))]),
        rate_table('parts', 'Known-AI parts: recall', parts),
        rate_table('current_models', 'Current models, base prompts, by model', by(current, 'factor_model')),
        rate_table('current_prompts', 'Current models, base prompts, by prompt', by(current, 'factor_prompt')),
        rate_table('ladder', 'Open-weight ladder, by era', by(df[samples == 'generated_ladder_2026_10'], 'factor_era')),
        rate_table('conditions', 'Stratified texts, by condition', by(stratified, 'condition', CONDITIONS)),
        rate_table('stratified_models', 'Stratified texts, by model', by(stratified, 'factor_model')),
        rate_table('agpedia_operators', 'Agpedia full articles, by operator',
                   by(df[samples == 'agpedia_2026_10'], 'factor_author')),
        calibration,
        term_trend(df, calibration),
    ]


def markdown_cell(cell, baseline=False):
    if cell is None:
        return ''
    if baseline:
        return f"{cell['k']}/{cell['n']} {100 * cell['rate']:.1f}% (≤{100 * cell['upper']:.1f})"
    return f"{cell['k']}/{cell['n']} {100 * cell['rate']:.0f}% ({100 * cell['lower']:.0f}–{100 * cell['upper']:.0f})"


def markdown(tables):
    lines = ['# Detector readout', '',
             'Cells: positives/units, rate, exact 95% interval. Positive = the vendor\'s own "AI" verdict, '
             'except "P4 >0.9", the Dashboard alert rule. Baseline cells show the upper bound only.', '']
    for table in tables:
        lines += [f"## {table['title']}", '']
        if table['kind'] == 'rates':
            lines += ['| group | ' + ' | '.join(DETECTORS.values()) + ' |', '|---|' + '---|' * len(DETECTORS)]
            for row in table['rows']:
                cells = [markdown_cell(row['cells'][d], table['key'] == 'baseline') for d in DETECTORS]
                lines.append(f"| {row['group']} | " + ' | '.join(cells) + ' |')
        elif table['kind'] == 'calibrated':
            lines += ['| detector | target FPR | threshold | baseline FPR | ' + ' | '.join(table['parts']) + ' |',
                      '|---|---|---|---|' + '---|' * len(table['parts'])]
            for row in table['rows']:
                recall = ['' if row['recall'][p] is None else f"{100 * row['recall'][p]:.0f}%" for p in table['parts']]
                lines.append(f"| {DETECTORS[row['detector']]} | {100 * row['target_fpr']:.1f}% | {row['threshold']:.3f} "
                             f"| {100 * row['baseline_fpr']:.1f}% | " + ' | '.join(recall) + ' |')
        else:
            names = list(table['thresholds'])
            lines += ['| term | units | ' + ' | '.join(f'{DETECTORS[d]} verdict | {DETECTORS[d]} > threshold'
                                                      for d in names) + ' |',
                      '|---|---|' + '---|---|' * len(names)]
            for row in table['rows']:
                cells = [f"{100 * row[k].get(d, 0):.0f}%" for d in names for k in ['verdict', 'above_threshold']]
                lines.append(f"| {row['term']} | {row['units']} | " + ' | '.join(cells) + ' |')
        lines.append('')
    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('export_csv', type=Path)
    parser.add_argument('--open-pangram', type=Path, nargs='*', default=[],
                        help='score files from score_open_pangram.py, joined on text_sha256')
    parser.add_argument('--markdown', type=Path)
    parser.add_argument('--json', type=Path)
    args = parser.parse_args()

    tables = readout(load(args.export_csv.expanduser(), [p.expanduser() for p in args.open_pangram]))
    text = markdown(tables)
    if args.markdown:
        args.markdown.expanduser().write_text(text)
    if args.json:
        args.json.expanduser().write_text(json.dumps({'detectors': DETECTORS, 'tables': tables}, indent=1))
    print(text)


if __name__ == '__main__':
    main()
