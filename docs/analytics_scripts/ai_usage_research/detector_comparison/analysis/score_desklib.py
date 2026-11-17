"""Score unit texts offline with Desklib's open AI text detector, for research only.

Desklib v1.01 (https://huggingface.co/desklib/ai-text-detector-v1.01, MIT licence) is
microsoft/deberta-v3-large fine-tuned on the RAID benchmark's training set: mean-pooled token
embeddings, then one linear logit, whose sigmoid is the probability that a text is AI-generated
(AI at 0.5 and above). The model class and its inference settings below follow the model card's
own code: 768 tokens, padded to that length, float32. The card truncates longer texts; units
here run to thousands of words, so each text is scored in consecutive 768-token windows (the last
one shifted back to end at the text's end), as score_open_pangram.py does. A text's document
score is the token-weighted mean of its window probabilities, its label is AI when that mean is
0.5 or more, and max_score is its highest window.

RAID (2024) draws on older generators (GPT-2 through GPT-4 and open models of that time) across
several domains, including, as far as we know, Wikipedia text. Expect weaker recall on current
models than the vendors', and treat its false-positive rate on pre-2023 Wikipedia text with the
same caution as the other detectors'.

Input: a CSV with a `text` column, plus `unit_id`, `sample_name` and `text_sha256` when it is a
unit-text export (the sha is computed when missing, matching the Dashboard's). Output: one row
per input row with the DetectorSummary columns that ImportOfflineDetectorScores reads.

`--verify N` first checks the windowing against the model card's single-call inference on the
first N texts short enough for one window: their scores must match.

Usage:
    python score_desklib.py --input ~/ai_detection_unit_texts_2026-11.csv \\
        --out ~/desklib_2026-11.csv --verify 20
"""

import argparse
import hashlib
import sys
from pathlib import Path

import pandas as pd
import torch
import torch.nn as nn

sys.path.insert(0, str(Path(__file__).resolve().parent))
from score_open_pangram import revision, special_token_count, windows  # noqa: E402

REPO = 'desklib/ai-text-detector-v1.01'
CHECK_TYPE = 'Desklib v1.01'
MAX_LENGTH = 768  # the model card's inference length
THRESHOLD = 0.5
COLUMNS = ['check_type', 'vendor', 'model_version', 'label', 'document_score', 'max_score',
           'mean_window_score', 'window_count', 'windows_above_0_5', 'windows_above_0_9',
           'scored_at', 'error']


def model_class():
    """The model card's DesklibAIDetectionModel (MIT, Desklib), defined late so that importing
    this module does not need transformers."""
    from transformers import AutoConfig, AutoModel, PreTrainedModel

    class DesklibAIDetectionModel(PreTrainedModel):
        config_class = AutoConfig

        def __init__(self, config):
            super().__init__(config)
            self.model = AutoModel.from_config(config)
            self.classifier = nn.Linear(config.hidden_size, 1)
            self.post_init()

        def forward(self, input_ids, attention_mask=None):
            last_hidden_state = self.model(input_ids, attention_mask=attention_mask)[0]
            mask = attention_mask.unsqueeze(-1).expand(last_hidden_state.size()).float()
            pooled = torch.sum(last_hidden_state * mask, dim=1) / torch.clamp(mask.sum(dim=1), min=1e-9)
            return {'logits': self.classifier(pooled)}

    return DesklibAIDetectionModel


def load_model(repo, device):
    from transformers import AutoTokenizer
    tokenizer = AutoTokenizer.from_pretrained(repo)
    model = model_class().from_pretrained(repo).to(device)
    model.eval()
    return tokenizer, model


@torch.no_grad()
def probabilities(chunks, tokenizer, model, device, batch_size):
    """AI probability of each chunk, tokenized as the model card does."""
    probs = []
    for i in range(0, len(chunks), batch_size):
        batch = tokenizer(chunks[i:i + batch_size], padding='max_length', truncation=True,
                          max_length=MAX_LENGTH, return_tensors='pt').to(device)
        logits = model(input_ids=batch['input_ids'], attention_mask=batch['attention_mask'])['logits']
        probs.append(torch.sigmoid(logits.float()).view(-1).cpu())
    return torch.cat(probs)


def score_text(text, tokenizer, model, device, batch_size):
    offsets = tokenizer(text, add_special_tokens=False, return_offsets_mapping=True)['offset_mapping']
    if not offsets:
        raise ValueError('empty text')
    # Windows are cut by token count, then re-tokenized from their text so the tokenizer adds its
    # own special tokens; truncation guards the rare boundary token that re-splits.
    spans = windows(len(offsets), MAX_LENGTH - special_token_count(tokenizer))
    chunks = [text[offsets[start][0]:offsets[end - 1][1]] for start, end in spans]
    probs = probabilities(chunks, tokenizer, model, device, batch_size)
    weights = torch.tensor([end - start for start, end in spans], dtype=torch.float32)
    weights /= weights.sum()
    document = float(weights @ probs)
    return {'label': 'AI' if document >= THRESHOLD else 'Human', 'document_score': document,
            'max_score': float(probs.max()), 'mean_window_score': document,
            'window_count': len(chunks), 'windows_above_0_5': int((probs > 0.5).sum()),
            'windows_above_0_9': int((probs > 0.9).sum())}


def verify(texts, tokenizer, model, device, count):
    """Windowed scores must equal the card's single call on texts that fit one window."""
    limit = MAX_LENGTH - special_token_count(tokenizer)
    short = [t for t in texts if len(tokenizer(t, add_special_tokens=False)['input_ids']) <= limit][:count]
    if not short:
        raise SystemExit('--verify: no input text fits in one window')
    windowed = [score_text(t, tokenizer, model, device, 1)['document_score'] for t in short]
    single = probabilities(short, tokenizer, model, device, 1).tolist()
    worst = max(abs(a - b) for a, b in zip(windowed, single))
    print(f'verify: {len(short)} single-window texts, largest difference from the card\'s inference {worst:.2e}')
    if worst > 1e-4:
        raise SystemExit('--verify failed: windowed scoring does not reproduce the card\'s inference')


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--input', type=Path, required=True, help='CSV with a text column')
    parser.add_argument('--out', type=Path, required=True, help='scores CSV to write (outside the repo)')
    parser.add_argument('--checkpoint', help='local clone of the model repo, instead of downloading it')
    parser.add_argument('--device', default='cuda' if torch.cuda.is_available() else 'cpu')
    parser.add_argument('--batch-size', type=int, default=4)
    parser.add_argument('--verify', type=int, default=0, metavar='N',
                        help='first check the windowing against the card\'s inference on N short texts')
    args = parser.parse_args()

    repo = str(Path(args.checkpoint).expanduser()) if args.checkpoint else REPO
    device = torch.device(args.device)
    tokenizer, model = load_model(repo, device)
    model_version = revision(repo)
    print(f'{repo} @ {model_version[:12]}: {MAX_LENGTH} tokens, on {device}')

    units = pd.read_csv(args.input.expanduser(), dtype={'text': 'string'}, low_memory=False)
    if 'text_sha256' not in units.columns:
        units['text_sha256'] = units['text'].map(lambda t: hashlib.sha256(str(t).encode('utf-8')).hexdigest())
    if args.verify:
        verify([str(t) for t in units['text']], tokenizer, model, device, args.verify)

    scored_at = pd.Timestamp.now(tz='UTC').isoformat()
    results = []
    for n, text in enumerate(units['text'], 1):
        row = {'check_type': CHECK_TYPE, 'vendor': 'desklib', 'model_version': model_version,
               'scored_at': scored_at, 'error': None}
        try:
            row.update(score_text(str(text), tokenizer, model, device, args.batch_size))
        except Exception as error:  # recorded per unit, like a failed vendor call
            row['error'] = str(error)[:500]
        results.append(row)
        if n % 100 == 0:
            print(f'{n}/{len(units)} scored')
    keys = [c for c in ['unit_id', 'sample_name', 'text_sha256'] if c in units.columns]
    scores = pd.concat([units[keys].reset_index(drop=True), pd.DataFrame(results)[COLUMNS]], axis=1)
    scores.to_csv(args.out.expanduser(), index=False)
    print(f"{len(scores)} rows written to {args.out}; {scores['error'].notna().sum()} errors; "
          f"labels: {scores['label'].value_counts().to_dict()}")


if __name__ == '__main__':
    sys.exit(main())
