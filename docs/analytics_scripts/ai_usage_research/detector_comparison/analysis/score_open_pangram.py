"""Score unit texts offline with the Open Pangram (EditLens) models, for research only.

Open Pangram (https://www.pangram.com/blog/introducing-open-pangram) is two EditLens models
that estimate how much of a text AI wrote or edited: `pangram/editlens_roberta-large` (512
tokens) and `pangram/editlens_Llama-3.2-3B` (a QLoRA adapter on `meta-llama/Llama-3.2-3B`,
1,024 tokens). Both are gated on Hugging Face and licensed CC BY-NC-SA 4.0; Pangram says they
must not be used to enforce AI policy in education, so they stay out of production alerting.

Each model sorts text into buckets from 0 (human) to n-1 (AI-generated); the score is the
expected bucket scaled to [0, 1], as in Pangram's own inference script. Text is cleaned with
EditLens's `clean_text` (imported from a local clone of https://github.com/pangramlabs/EditLens,
not copied here: that code is CC BY-NC-SA). Their script truncates at the model's context; units
here run to thousands of words, so each text is scored in consecutive windows (the last one
shifted back to end at the text's end), giving a max window score, a length-weighted mean, and
the document's bucket.

Input: a CSV with a `text` column, plus `unit_id`, `sample_name` and `text_sha256` when it is a
unit-text export (the sha is computed when missing, matching the Dashboard's). Output: one row
per input row with the detector columns of ExportAiDetectionComparison. `--merge-with` adds those
rows, with each unit's columns copied from an existing comparison export (matched on
`text_sha256`), to that export, so analyze.py reads both together.

Usage:
    python score_open_pangram.py --editlens-repo ~/EditLens --model roberta \\
        --input ~/ai_detection_unit_texts_2026-10.csv --out ~/open_pangram_roberta_2026-10.csv \\
        --merge-with ~/detector_comparison_2026-10.csv --merged-out ~/detector_comparison_2026-10_with_open.csv
"""

import argparse
import hashlib
import subprocess
import sys
from pathlib import Path

import pandas as pd
import torch

MODELS = {
    'roberta': dict(check_type='Open Pangram EditLens RoBERTa', repo='pangram/editlens_roberta-large',
                    base='FacebookAI/roberta-large', max_length=512),
    'llama': dict(check_type='Open Pangram EditLens Llama', repo='pangram/editlens_Llama-3.2-3B',
                  base='meta-llama/Llama-3.2-3B', max_length=1024),
}
LABELS = {0: 'Human'}  # top bucket is 'AI'; buckets between are 'AI-edited <n>'
DETECTOR_COLUMNS = ['check_type', 'vendor', 'model_version', 'label', 'document_score', 'max_score',
                    'mean_window_score', 'window_count', 'scored_at', 'error']


class ScoreHead(torch.nn.Module):
    """LayerNorm then a bias-free linear layer: the shape of the Llama adapter's score head."""

    def __init__(self, hidden_size, num_labels, device=None):
        super().__init__()
        self.norm = torch.nn.LayerNorm(hidden_size, device=device)
        self.linear = torch.nn.Linear(hidden_size, num_labels, bias=False, device=device)

    def forward(self, hidden):
        return self.linear(self.norm(hidden))


def adapter_buckets(repo):
    from huggingface_hub import hf_hub_download
    from safetensors import safe_open
    local = Path(repo, 'adapter_model.safetensors')
    path = local if local.exists() else hf_hub_download(repo, 'adapter_model.safetensors')
    with safe_open(path, framework='pt') as weights:
        for key in weights.keys():
            if 'score' in key and 'linear.weight' in key:
                return weights.get_tensor(key).shape[0]
    raise ValueError(f'no score head in {repo}')


def revision(repo):
    """Commit of a Hub repo, or of a local git clone of one."""
    if Path(repo).is_dir():
        return subprocess.run(['git', '-C', repo, 'rev-parse', 'HEAD'], capture_output=True, text=True,
                              check=True).stdout.strip()
    from huggingface_hub import model_info
    return model_info(repo).sha


def load_model(spec, device):
    from transformers import AutoModelForSequenceClassification, AutoTokenizer
    tokenizer = AutoTokenizer.from_pretrained(spec['base'])
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token
        tokenizer.padding_side = 'left'
    if 'roberta' in spec['base']:
        model = AutoModelForSequenceClassification.from_pretrained(spec['repo']).to(device)
        buckets = model.config.num_labels
    else:
        from peft import PeftModel
        from transformers import BitsAndBytesConfig
        buckets = adapter_buckets(spec['repo'])
        base = AutoModelForSequenceClassification.from_pretrained(
            spec['base'], num_labels=buckets,
            quantization_config=BitsAndBytesConfig(load_in_4bit=True, bnb_4bit_quant_type='nf4',
                                                   bnb_4bit_compute_dtype=torch.bfloat16))
        base.config.pad_token_id = tokenizer.pad_token_id
        base.score = ScoreHead(base.config.hidden_size, buckets, device=next(base.parameters()).device)
        model = PeftModel.from_pretrained(base, spec['repo'])
    model.eval()
    return tokenizer, model, buckets, revision(spec['repo'])


def windows(count, size):
    """Token spans covering a text in consecutive windows, the last one ending at the end."""
    if count <= size:
        return [(0, count)]
    starts = list(range(0, count, size))
    starts[-1] = count - size
    return [(start, start + size) for start in starts]


def special_token_count(tokenizer):
    return len(tokenizer('a')['input_ids']) - len(tokenizer('a', add_special_tokens=False)['input_ids'])


@torch.no_grad()
def score_text(text, clean_text, tokenizer, model, buckets, max_length, device, batch_size):
    cleaned = clean_text(text)
    offsets = tokenizer(cleaned, add_special_tokens=False, return_offsets_mapping=True)['offset_mapping']
    if not offsets:
        raise ValueError('empty text after cleaning')
    # Windows are cut by token count, then re-tokenized from their text so the tokenizer adds
    # its own special tokens; truncation guards the rare boundary token that re-splits.
    spans = windows(len(offsets), max_length - special_token_count(tokenizer))
    chunks = [cleaned[offsets[start][0]:offsets[end - 1][1]] for start, end in spans]
    probs = []
    for i in range(0, len(chunks), batch_size):
        batch = tokenizer(chunks[i:i + batch_size], truncation=True, max_length=max_length, padding=True,
                          return_tensors='pt').to(device)
        with torch.autocast(device.type, dtype=torch.bfloat16, enabled=device.type == 'cuda'):
            logits = model(**batch).logits
        probs.append(torch.softmax(logits.float(), dim=-1).cpu())
    probs = torch.cat(probs)
    scale = torch.arange(buckets, dtype=torch.float32) / (buckets - 1)
    scores = probs @ scale
    weights = torch.tensor([end - start for start, end in spans], dtype=torch.float32)
    weights /= weights.sum()
    document_probs = weights @ probs
    bucket = int(document_probs.argmax())
    label = 'AI' if bucket == buckets - 1 else LABELS.get(bucket, f'AI-edited {bucket}')
    return {'label': label, 'document_score': float(document_probs @ scale), 'max_score': float(scores.max()),
            'mean_window_score': float(weights @ scores), 'window_count': len(chunks)}


def merge(scores, export_path, out_path):
    export = pd.read_csv(export_path, low_memory=False)
    units = export.drop(columns=[c for c in DETECTOR_COLUMNS + ['score_id', 'report_url'] if c in export.columns])
    units = units.drop(columns=[c for c in units.columns if c.startswith(('windows_above', 'fraction_', 'humanized', 'max_humanizer'))])
    units = units.drop_duplicates('unit_id')
    rows = units.merge(scores[['text_sha256'] + DETECTOR_COLUMNS], on='text_sha256', how='inner')
    merged = pd.concat([export, rows], ignore_index=True)
    merged.to_csv(out_path, index=False)
    print(f'{len(rows)} unit rows merged into {out_path} ({len(merged)} rows in all)')


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--editlens-repo', type=Path, required=True, help='local clone of pangramlabs/EditLens')
    parser.add_argument('--model', choices=MODELS, required=True)
    parser.add_argument('--checkpoint', help='local clone of the model repo, instead of downloading it')
    parser.add_argument('--base', help='local clone of the base model, instead of downloading it')
    parser.add_argument('--input', type=Path, required=True, help='CSV with a text column')
    parser.add_argument('--out', type=Path, required=True, help='scores CSV to write (outside the repo)')
    parser.add_argument('--merge-with', type=Path, help='comparison export to add the scores to')
    parser.add_argument('--merged-out', type=Path)
    parser.add_argument('--device', default='cuda' if torch.cuda.is_available() else 'cpu')
    parser.add_argument('--batch-size', type=int, default=8)
    args = parser.parse_args()

    sys.path.insert(0, str(args.editlens_repo.expanduser() / 'scripts'))
    from preprocess import clean_text

    spec = dict(MODELS[args.model])
    spec['repo'] = str(Path(args.checkpoint).expanduser()) if args.checkpoint else spec['repo']
    spec['base'] = str(Path(args.base).expanduser()) if args.base else spec['base']
    device = torch.device(args.device)
    tokenizer, model, buckets, revision = load_model(spec, device)
    print(f"{spec['repo']} @ {revision[:12]}: {buckets} buckets, {spec['max_length']} tokens, on {device}")

    units = pd.read_csv(args.input.expanduser(), dtype={'text': 'string'}, low_memory=False)
    if 'text_sha256' not in units.columns:
        units['text_sha256'] = units['text'].map(lambda t: hashlib.sha256(str(t).encode('utf-8')).hexdigest())
    scored_at = pd.Timestamp.now(tz='UTC').isoformat()
    results = []
    for n, text in enumerate(units['text'], 1):
        row = {'check_type': spec['check_type'], 'vendor': 'open_pangram', 'model_version': revision,
               'scored_at': scored_at, 'error': None}
        try:
            row.update(score_text(str(text), clean_text, tokenizer, model, buckets, spec['max_length'],
                                  device, args.batch_size))
        except Exception as error:  # recorded per unit, like a failed vendor call
            row['error'] = str(error)[:500]
        results.append(row)
        if n % 50 == 0:
            print(f'{n}/{len(units)} scored')
    keys = [c for c in ['unit_id', 'sample_name', 'text_sha256'] if c in units.columns]
    scores = pd.concat([units[keys].reset_index(drop=True), pd.DataFrame(results)], axis=1)
    scores.to_csv(args.out.expanduser(), index=False)
    print(f"{len(scores)} rows written to {args.out}; {scores['error'].notna().sum()} errors; "
          f"labels: {scores.get('label', pd.Series(dtype=str)).value_counts().to_dict()}")
    if args.merge_with:
        merge(scores, args.merge_with.expanduser(), args.merged_out.expanduser())


if __name__ == '__main__':
    sys.exit(main())
