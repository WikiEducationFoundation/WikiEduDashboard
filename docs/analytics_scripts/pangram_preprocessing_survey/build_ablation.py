"""Build ablation inputs from the sampled texts, for score_ablation.rb.

    python3 -I build_ablation.py ~/pangram_preprocessing_survey

Writes ablation_inputs.json, a list of {id, rev, group, text}:
- template: 30 alert-level Outline / Evaluate / Choose checks whose hot windows touch
  template text (student false-positive claims first), with template lines removed.
- citation: 30 alert-level Bibliography / Choose / sandbox checks with 3+ citation
  lines, at least one in a hot window, with citation lines removed.
- baseline: 10 of those checks' texts unchanged, to measure re-scoring drift.
Run analyze.py first; it writes check_summary.json, which this reads.
"""
import importlib.util
import json
import random
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('analyze', HERE / 'analyze.py')
analyze = importlib.util.module_from_spec(spec)
spec.loader.exec_module(analyze)


def main(data_dir):
    data_dir = Path(data_dir).expanduser()
    rng = random.Random(20261117)
    summary = {c['rev']: c for c in json.loads((data_dir / 'check_summary.json').read_text())}
    texts = {int(p.stem): json.loads(p.read_text()) for p in (data_dir / 'texts').glob('*.json')}
    template_lines = json.loads((data_dir / 'template_lines.json').read_text())
    boilerplate = {analyze.normalize(line) for ls in template_lines.values() for line in ls
                   if len(line.split()) >= 2}
    boilerplate |= set(json.loads((data_dir / 'repeated_lines.json').read_text()))

    def kinds(rev):
        return [(a, b, raw, analyze.classify(raw, boilerplate))
                for a, b, raw in analyze.lines_with_offsets(texts[rev]['prompt'])]

    def without(rev, kind):
        return '\n'.join(raw for _a, _b, raw, k in kinds(rev) if k != kind)

    def hot_touches(rev, kind):
        hot = [w for w in texts[rev]['windows'] if analyze.score(w) > analyze.HOT]
        return any(k == kind and w['start_index'] < b and w['end_index'] > a
                   for a, b, _raw, k in kinds(rev) for w in hot)

    exercise = [c for c in summary.values() if c['hot'] and c['template_hot']
                and c['pt'] in ('outline', 'evaluate_an_article', 'choose_an_article')]
    claimed = [c for c in exercise if c['fp_claim']]
    others = [c for c in exercise if not c['fp_claim']]
    template_pick = rng.sample(claimed, min(20, len(claimed)))
    template_pick += rng.sample(others, 30 - len(template_pick))

    cited = [c for c in summary.values() if c['hot'] and c['kinds'].get('citation', 0) >= 3
             and c['pt'] in ('bibliography', 'choose_an_article', 'sandbox')
             and c['rev'] not in {t['rev'] for t in template_pick}
             and hot_touches(c['rev'], 'citation')]
    citation_pick = rng.sample(cited, min(30, len(cited)))

    inputs = [{'id': f"template_{c['rev']}", 'rev': c['rev'], 'group': 'template',
               'text': without(c['rev'], 'template')} for c in template_pick]
    inputs += [{'id': f"citation_{c['rev']}", 'rev': c['rev'], 'group': 'citation',
                'text': without(c['rev'], 'citation')} for c in citation_pick]
    for c in rng.sample(template_pick, 5) + rng.sample(citation_pick, 5):
        inputs.append({'id': f"baseline_{c['rev']}", 'rev': c['rev'], 'group': 'baseline',
                       'text': texts[c['rev']]['prompt']})
    for i in inputs:
        if i['group'] != 'baseline' and i['text'] == texts[i['rev']]['prompt']:
            raise ValueError(f"{i['id']}: nothing removed")
    (data_dir / 'ablation_inputs.json').write_text(json.dumps(inputs))
    print({g: sum(i['group'] == g for i in inputs) for g in ('template', 'citation', 'baseline')},
          f"({sum(c['fp_claim'] for c in template_pick)} template checks with FP claims;"
          f" {len(cited)} citation candidates)")


if __name__ == '__main__':
    main(sys.argv[1])
