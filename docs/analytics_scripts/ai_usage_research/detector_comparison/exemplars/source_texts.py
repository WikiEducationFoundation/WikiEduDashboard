"""Write the source texts (the text as written, with citations) for challenge-set units.

The sample CSVs carry only the cleaned text the detectors score. This writes a separate CSV
of text_sha256, source_text, source_format for the units in a sample CSV, which
backfill_source_text.rb uses to fill ai_detection_samples.source_text by matching the hash of
the cleaned text. The hash is computed here exactly as the Dashboard computes it.

- Generated units: the model's whole final reply (source_format model_reply), from the
  stored generation records, or the page it wrote the draft to when the reply only points there.
- Agpedia units: the pinned revision's markdown (source_format markdown) from the archive
  that collect_agpedia.py keeps; lead units get the part before the first heading.

`prompts` writes text_sha256 and the prompts each generated unit was produced from, as a JSON
list of turns, for backfill_prompts_from_csv in the same Ruby script. The assignment flow's
outline turn quotes the whole article as it stood before the student's term; it is stored with
{prior_article} in place of that text, and the Dashboard links to the revision instead.

Usage:
    python source_texts.py generated --csv ~/detector_exemplars/generated_all_2026-10-07.csv \\
        --store ~/detector_exemplars/generated --out ~/detector_exemplars/generated_sources_2026-10.csv
    python source_texts.py agpedia --csv ~/detector_exemplars/agpedia_2026-10.csv \\
        --csv ~/detector_exemplars/agpedia_topics_2026-10-06.csv \\
        --out ~/detector_exemplars/agpedia_sources_2026-10.csv
    python source_texts.py prompts --csv ~/detector_exemplars/generated_all_2026-10-09_v4.csv \\
        --out ~/detector_exemplars/generated_prompts_2026-10.csv
"""

import argparse
import csv
import hashlib
import json
import sys
from pathlib import Path

from generate_texts import slug

csv.field_size_limit(sys.maxsize)


def sha256(text):
    return hashlib.sha256(text.encode('utf-8')).hexdigest()


def read_rows(paths):
    for path in paths:
        with Path(path).expanduser().open() as handle:
            yield from csv.DictReader(handle)


def generated_sources(rows, store):
    for row in rows:
        record = store / slug(row['factor_model']) / row['condition'] / f"{slug(row['factor_topic'])}.json"
        if record.exists():
            data = json.loads(record.read_text())
            # A draft the model wrote to a ChatGPT page, recovered by hand, is the text as written.
            source = (data.get('recovered_page') or {}).get('text') or data['raw_output']
            yield sha256(row['text']), source, 'model_reply'


PRIOR_ARTICLE = '{prior_article}'


def stored_prompts(record):
    turns = list(record.get('prompts') or [record['prompt']])
    if record.get('prior_rev_id'):
        head, label, _article = turns[1].partition('Current article:\n\n')
        turns[1] = head + label + PRIOR_ARTICLE
    return turns


def generated_prompts(rows, store):
    for row in rows:
        record = store / slug(row['factor_model']) / row['condition'] / f"{slug(row['factor_topic'])}.json"
        if record.exists():
            yield sha256(row['text']), json.dumps(stored_prompts(json.loads(record.read_text())), ensure_ascii=False)


def lead_markdown(markdown):
    lines = []
    for line in markdown.splitlines():
        if line.startswith('#'):
            break
        lines.append(line)
    return '\n'.join(lines).strip()


def agpedia_sources(rows, archive):
    for row in rows:
        page_slug = row['url'].split('?')[0].rsplit('/', 1)[-1]
        path = archive / f"{page_slug}-{row['agpedia_rev_id']}.md"
        if not path.exists():
            continue
        markdown = path.read_text()
        source = markdown if row['factor_excerpt'] == 'full' else lead_markdown(markdown)
        yield sha256(row['text']), source, 'markdown'


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('kind', choices=['generated', 'agpedia', 'prompts'])
    parser.add_argument('--csv', action='append', required=True, help='sample CSV (repeatable)')
    parser.add_argument('--store', type=Path, default=Path('~/detector_exemplars/generated'))
    parser.add_argument('--archive', type=Path, default=Path('~/detector_exemplars/agpedia_archive'))
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()

    rows = list(read_rows(args.csv))
    if args.kind == 'prompts':
        prompts = dict(generated_prompts(rows, args.store.expanduser()))
        with args.out.expanduser().open('w', newline='') as handle:
            writer = csv.writer(handle)
            writer.writerow(['text_sha256', 'prompts'])
            writer.writerows(prompts.items())
        print(f'{len(prompts)} prompt lists for {len(rows)} rows written to {args.out}')
        return
    if args.kind == 'generated':
        sources = generated_sources(rows, args.store.expanduser())
    else:
        sources = agpedia_sources(rows, args.archive.expanduser())
    seen = {}
    for sha, source, source_format in sources:
        seen.setdefault(sha, (source, source_format))
    with args.out.expanduser().open('w', newline='') as handle:
        writer = csv.writer(handle)
        writer.writerow(['text_sha256', 'source_text', 'source_format'])
        for sha, (source, source_format) in seen.items():
            writer.writerow([sha, source, source_format])
    print(f'{len(seen)} source texts for {len(rows)} rows written to {args.out}')


if __name__ == '__main__':
    sys.exit(main())
