# Comparing AI detectors

A repeatable way to send the same texts to several AI detectors, store every result
in one shape, and compare detectors against each other. It replaced the one-off
script in this directory (`signal_and_false_positives.rb`, March 2026), whose result
CSV can be imported so its Pangram 3 and Originality scores are reused.

Everything below runs in a Rails console on the production server, where the course
data, the existing scores and the API keys live. Analysis runs locally in Python on
an exported CSV.

## Concepts

- **Detector**: an API client plus a response parser, registered in
  `lib/ai/ai_detector.rb` under the `RevisionAiScore#check_type` its results are stored
  as. Every parser exposes the same `summary` (see `lib/ai/detector_summary.rb`), so
  analysis never depends on the vendor. Adding a detector is a client, a parser and one
  registry entry.
- **Sample**: a named set of text units in `ai_detection_samples`, each holding the
  exact text sent to detectors and where it came from (wiki, revision, diff, term), or
  just the text for units that did not come from a wiki revision.
- **Source text**: the unit's text as written, before it was cleaned for the detectors,
  with its citations and references, for later analysis such as claim verification.
  `source_format` says what it is: `wikitext` (revision units get it automatically: the
  wikitext a diff added, or the whole revision's), `markdown` (Agpedia), or `model_reply`
  (a model's whole reply, from which the cleaned text was extracted). Rows can carry
  `source_text` and `source_format` columns. Units built before October 2026 were
  backfilled with `backfill_source_text.rb`.
- **Ground truth and provenance**: `ground_truth` is what we know about how the text was
  produced (`human`, `ai`, `ai_assisted`, or blank for unknown); `provenance` is how we
  know it (`pre_llm_term`, `staff_confirmed`, `experiment`, `synthetic`, `self_report`, or
  any description an ad-hoc source needs). Student questionnaire answers are recorded as
  `self_report` provenance with no ground truth: they are never treated as truth, only
  used to surface cases worth confirming by hand. `notes` holds what makes a case
  interesting.
- **Factors**: named values on a unit (`topic`, `author`, `model`, `prompt`,
  `post_processing`, anything) that link units sharing a value. A known-human article
  and a synthetic article on the same subject share `topic`; exemplars generated the same
  way share `model` and `prompt`. Pairs and groups are just units with equal factor
  values, so no extra tables are needed. `unit.linked_by(:topic)` finds a unit's partners.
- **Score**: a `revision_ai_scores` row with `check_origin = 'detector_comparison'`
  and `sample_id` set. Production alerting and the admin AI tools page are unaffected.

## Credits

Pangram is billed per word at a rate we can afford at scale. Originality.ai bills about
one credit per 100 words per check for both 5.0 models through the API (observed
2026-11-17; their pricing page lists 5.0 Max at ten times that, so check the balance
before and after a first Max run). Always dry-run first.

Detectors offered for comparison scoring are `AiDetector.keys`: Pangram 4.1, Originality
5.0 and Originality 5.0 Max (since 2026-11). Retired detectors keep their stored rows:
Pangram 3 (API shut down 2026-09-30); comparison rows under `Pangram 4`, all scored as
4.0 before Pangram moved `pangram-4` to 4.1 on 2026-10-19 (to be relabelled `Pangram 4.0`
when the comparison page shows 4.0 and 4.1 side by side); and Originality's classic
models and AI Allowance 15/40 (replaced by 5.0). `Pangram 4.1` refuses results from any other
version, and scoring stops when Pangram or Originality answers with a different model
than the key names. Production alerting keeps the `Pangram 4` key, which follows
whatever version Pangram serves (`details['version']` records it).

## 1. Build a sample

Each builder fetches the plaintext once per unit, skips units with less than 500
characters of prose, and never adds a unit to a sample twice. All accept `verbose: true`.

Edits production already scored, stratified by the production max score
(40 per band: below 0.5, 0.5 to 0.9, 0.9 and up), from the last 30 days:

```ruby
builder = BuildAiDetectionSampleFromRecentScores.new(sample_name: 'recent_2026_09', per_band: 40, verbose: true)
builder.summary
```

Alerts whose student answered the follow-up questionnaire. The answers are recorded as
`self_report` provenance and metadata only; ground truth stays unset:

```ruby
BuildAiDetectionSampleFromAlertFollowups.new(sample_name: 'followups', since: 1.year.ago, verbose: true).summary
```

The March 2026 method, cumulative course diffs of substantial articles per term:

```ruby
BuildAiDetectionSampleFromArticlesByTerm.new(sample_name: 'terms_2026_09', terms: %w[spring_2022 fall_2025 spring_2026], per_term: 50, verbose: true).summary
```

Any rows naming units by URL or by text, with whatever we know about them:

```ruby
BuildAiDetectionSampleFromRows.new(sample_name: 'challenge', rows: [
  { url: 'https://en.wikipedia.org/w/index.php?diff=1315039613&oldid=1310000000',
    ground_truth: 'human', provenance: 'staff_confirmed', notes: 'instructor confirmed; Pangram 3 max 0.87 on 2026-04-12',
    factors: { 'topic' => 'Urban beekeeping' } },
  { text: File.read('/home/sage/exemplars/beekeeping_gpt5_naive.txt'), ground_truth: 'ai', provenance: 'synthetic',
    factors: { 'topic' => 'Urban beekeeping', 'model' => 'gpt-5', 'prompt' => 'naive', 'post_processing' => 'none' } }
])
```

Or a CSV. `url_column` (default `url`) names a diff or revision; `text_column` (default
`text`) holds the text itself and wins when present. Columns `ground_truth`, `provenance`,
`notes` and `campaign_slug` become unit attributes; `factor_*` columns become factors;
every other column is kept as metadata. Defaults apply to rows without their own value:

```ruby
BuildAiDetectionSampleFromRows.from_csv(sample_name: 'wvs_neu', path: 'docs/analytics_scripts/wvs_neu_ai_edits/dataset.csv', url_column: 'diff_url', ground_truth: 'ai', provenance: 'experiment', verbose: true)
BuildAiDetectionSampleFromRows.from_csv(sample_name: 'exemplars_2026_09', path: '/home/sage/exemplars.csv', provenance: 'synthetic', verbose: true)
```

Fetching and preprocessing text from any particular source (another wiki, a dump, an
AI-writing platform, our own generation runs) happens outside the Dashboard; the result
is just rows in this shape.

The March 2026 comparison CSV, with the Pangram 3, Originality Turbo and Originality
Academic scores it already contains (copy the CSV to the server first):

```ruby
importer = ImportDetectorComparisonCsv.new(sample_name: 'terms_2021_2025_march', path: '/home/sage/ai_detection_comparison_march_2026.csv', pangram_version: '3.2', verbose: true)
importer.builder.summary
importer.imported
```

## 2. Dry-run, then score

```ruby
detectors = [RevisionAiScore::PANGRAM_V4_1_KEY, RevisionAiScore::ORIGINALITY_5_KEY, RevisionAiScore::ORIGINALITY_5_MAX_KEY]
ScoreAiDetectionSample.new(sample_name: 'recent_2026_09', detectors:, dry_run: true).report
```

The report lists pending units and words per detector, the estimated Originality
credits, and the current Originality balance. When that looks right:

```ruby
ScoreAiDetectionSample.new(sample_name: 'recent_2026_09', detectors:, verbose: true).report
```

Scoring is resumable: interrupt it and run the same line again. Units a detector has
already scored are skipped; failed calls are recorded with a nil average likelihood and
retried on the next run. `limit:` scores only the first N units.

## 3. Export

```ruby
ExportAiDetectionComparison.new(sample_names: %w[terms_2021_2025_march recent_2026_09]).to_csv('/home/sage/detector_comparison_2026-09.csv')
```

One row per unit and detector, with the unit's identity and ground truth followed by
the shared summary keys. Rows imported from the March CSV carry their summary
directly; failed calls appear with an `error` column and no scores. Copy the file to
your machine for analysis. `include_text: true` adds `plain_text`, `source_format` and
`source_text` columns; they are large and repeat on every detector row, so they are
left out by default.

## Scoring the core texts with a new detector

When a vendor releases a model, score the texts the comparison page is built on, the
known-human texts and the topics dataset (about 1,756 distinct texts), so the new
model sits next to every earlier one. `ScoreDetectorComparisonCore` does it in the
background, one ten-text chunk at a time on the `report_csv` Sidekiq queue (kept off
`default`, which runs the production AI checks one job at a time), with every
current detector (`AiDetector.keys`) in turn. In a production console:

```ruby
ScoreDetectorComparisonCore.plan                                    # pending texts, credits, balance
ScoreDetectorComparisonCore.start(max_originality_credits: 40_000)  # queue the run
ScoreDetectorComparisonCore.status                                  # progress, or why it stopped
ScoreDetectorComparisonCore.stop                                    # stop after the current chunk
```

`start(detectors: [...])` limits the run to some detectors. The run stops on its own,
saying why in `status['message']`, when:
- a vendor answers with a different model version;
- ten calls in a row fail, or 50 calls of one detector fail;
- Originality credits spent since this start pass `max_originality_credits`;
- an Originality model's first ten texts cost more than twice the estimate. This check
  is for 5.0 Max, which Originality's pricing page lists at ten times 5.0's price.

A text whose call fails is not sent again in the same run. Starting again continues
where the run stopped and retries those texts. `start` refuses while a run is in
progress. If a deploy or crash lost the run's job, `status` stays `running` with
nothing queued; `start(..., force: true)` then replaces the run, and any job of the
old run still in flight exits without saving.

To analyze the results locally, export them in production and load them into the
local copy, where the earlier detectors' scores already are:

```ruby
ExportDetectorComparisonScores.new('/home/sage/detector_comparison_core_scores_2026-11.jsonl').count
```

```sh
bin/rails runner docs/analytics_scripts/ai_usage_research/detector_comparison/load_core_scores.rb \
  ~/detector_comparison_core_scores_2026-11.jsonl
```

The export holds scores and window or segment details, no text.

## Exemplars and challenge cases

The longitudinal sample answers "how do detectors behave on typical student work over
time", with the pre-ChatGPT terms as a human baseline where the expected hit rate is zero.
Challenge cases answer "how do they behave on cases we understand": known-human edits with
high scores, known-AI text that was missed, text produced the way students might produce
it. They accumulate opportunistically as a `challenge` sample built from rows, each with a
real `ground_truth`, a `provenance` saying how we know, a note, and factors linking it to
related units.

Synthetic exemplars should vary along the dimensions students vary along, recorded as
factors so recall can be reported per cell: `model` (frontier, free tier, older),
`prompt` (one line; detailed with style and sourcing; "improve my draft", which yields
`ai_assisted`), `post_processing` (none; an automated humanizer; light human edits), and
`topic` shared with a known-human unit so the pair controls for subject. Keep Originality
to a subset of exemplars; Pangram can run on all of them.

### Building exemplars (`exemplars/`)

These scripts run on a workstation and write CSVs for `BuildAiDetectionSampleFromRows`;
their output stays outside the repo (`~/detector_exemplars/` by convention).

- `generate_texts.py` generates texts per (model, condition, topic) through tools already
  installed locally: Claude Code, Codex, Antigravity or the Gemini API, and Ollama for
  open-weight models. Each tool's own system prompt is replaced with a neutral one, and
  tools are off except in the web conditions. `CONDITIONS` changes one thing at a time
  from the base prompts: requested length, web access, a human-written or ChatGPT-written
  prompt, or Wiki Education's three-turn assignment flow (bibliography, outline of changes
  to the article as it stood before the student's term, draft) in its own training-module
  wording. Prompts written outside the script are kept verbatim in `exemplars/prompts/`:
  `human_prompts.txt` (separated by `===` lines, rotated across topics) and
  `chatgpt_prompt.txt`. Every call is stored as JSON with its prompts and raw replies, so
  runs resume where they stopped; `--assemble` extracts the draft a student would paste
  (dropping chat framing, advice, reference lists and markup) into the builder CSV. It
  also drops the notes models wrap around a draft about the edit itself (scope, what is
  missing, notes before publication). Codex runs with ChatGPT workspace apps off
  (`features.apps=false`): with them on, Codex reached the web and ChatGPT pages even with
  web search disabled, and the runs that did so are kept apart in the observed-only
  condition `assignment_apps_web`.
- `collect_agpedia.py` collects Agpedia articles (agent-written, CC0) as full-article and
  lead units pinned to a revision, skipping articles with direct operator edits, and
  archives each revision's markdown and rendered page.
- `source_texts.py` writes the source texts for those units (the model's whole reply, or
  the Agpedia markdown) for `backfill_source_text.rb`, and with `prompts` the prompts each
  generated text came from, for `backfill_prompts_from_csv` in the same script.

When a regenerated CSV changes the cleaned text or labels of a sample already built in
production, `sync_sample_from_csv.rb` brings the sample in line: units whose text is no
longer in the CSV move to a retired sample name with their scores attached, unchanged units
take the CSV's current notes and factors, and new texts are added by the usual builder.

### Open Pangram (`analysis/score_open_pangram.py`)

Scores unit texts offline with Pangram's open EditLens models (RoBERTa-large and a
Llama 3.2 3B adapter), for research only: they are licensed CC BY-NC-SA and Pangram says
not to use them to enforce AI policy in education. It imports EditLens's text cleaning from
a local clone of https://github.com/pangramlabs/EditLens rather than copying that code
here, scores long texts in windows, and writes rows in the export's format (`--merge-with`
adds them to an export for `analyze.py`). On 900 texts from EditLens's own validation and
test splits it reproduces Pangram's published results (human vs AI-generated macro F1
0.995 for RoBERTa against 0.997 reported).

Open Pangram scores reach the Dashboard through `ImportOfflineDetectorScores`, which takes a
score file from `score_open_pangram.py` (or any offline detector writing the same columns)
and stores each row against every unit with that text:

```ruby
importer = ImportOfflineDetectorScores.new(path: '/home/sage/all_units_llama_2026-10-12.csv')
[importer.imported, importer.unmatched]
```

### Desklib (`analysis/score_desklib.py`)

Scores unit texts offline with Desklib's open detector, `desklib/ai-text-detector-v1.01`
(MIT licence; DeBERTa-v3-large fine-tuned on RAID's training set). It follows the model
card's own inference code (768 tokens, padded to that length, float32, AI at a
probability of 0.5), scores long texts in consecutive 768-token windows, and writes rows
under the check type `Desklib v1.01` in the format `ImportOfflineDetectorScores` reads.
The document score is the token-weighted mean of the window probabilities; `max_score`
is the highest window. `--verify N` first checks that windowed scoring reproduces the
card's single call on N texts that fit one window.

It runs in the same environment as Open Pangram (`~/.venvs/open_detectors`); the
DeBERTa-v3 tokenizer may also need `pip install sentencepiece`. The weights are about
1.7 GB, and in float32 the model fits easily on an 8 GB GPU. The input is the
`text_sha256,word_count,text` file used for Open Pangram, covering every distinct text
in the production samples:

```sh
python score_desklib.py --input ~/desklib_input_2026-11-17.csv --out ~/desklib_2026-11-17.csv --verify 20
```

Load the scores locally first for analysis, and into production when the comparison
page should show them, with `ImportOfflineDetectorScores.new(path: ...)` as above.

First run, 2026-11-17 (model commit 5fdea974cd42): 4,185 distinct texts, no errors, about
35 minutes on an RTX 3070 Ti; `--verify 20` matched the card's inference exactly. Against
the comparison page's data, counting any AI label as a detection:

- **Known-human texts** (578 pre-ChatGPT student contributions): Desklib labels 54 (9.3%)
  AI, against 0 for Pangram 4.0 and Originality Allowance 15/40 and 1–2 for Open Pangram.
  With a Dashboard-style rule on its windows instead of its document score, 171 (30%) have
  a window at 0.5 or more and 40 (6.9%) one above 0.9.
- **What the 54 have in common:** nothing beyond the model. They are spread evenly across
  terms, with flag rates of 5–13 per term of about 95 texts. Pangram 4.0 and Open Pangram
  score all of them as clearly human. Shorter texts are flagged more often: 5 of 23 under
  300 words, 4 of 116 over 2,000 words, since the document score averages windows. So are
  texts that open like an encyclopedia lead ("X is a ..."), at 12% against 7%. Wikitext
  leftovers in the extracted text are as common in unflagged texts.
- **Score spread:** the flagged scores spread from 0.50 to 0.98, and another 89 human texts
  score between 0.3 and 0.5. Desklib's scores on encyclopedic human prose are broad, not a
  few outliers.
- **Generated texts:** AI labels on 86% of current models' texts from simple prompts (Pangram
  4.0: 100%) and 65% from other prompting strategies (96%), 100% of the older open-weight
  models' texts, and 1 of 16 Agpedia articles (14 of 16).

## The comparison page

`/detector_comparison` (public, on the Wiki Education Dashboard) presents the known-AI samples
(provenance `synthetic` or `agpedia`) and the human baseline texts they are paired with.
Each text has its own page with the text, Pangram's windows marked on it, every detector's
result, the prompts and the text as written. For a new generated sample, run the source and
prompt backfills after building it; units in samples whose names end in `_retired` are
left out.

The page serves a published snapshot, not the database: new samples and scores appear
only after publishing, in a Rails console (about 15 seconds for ~1,800 texts):

```ruby
PublishDetectorComparison.new.counts
```

Each publication is a directory under `detector_comparison_snapshots/` (a shared directory
on the server), and `current` points to the newest; the last three are kept. The
introduction and conclusions in `config/detector_comparison_page.yml` are read on each
request, so they change on deploy without publishing.

## 4. Analyze

```sh
cd docs/analytics_scripts/ai_usage_research/detector_comparison/analysis
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
.venv/bin/python analyze.py ~/detector_comparison_2026-09.csv --out ~/detector_results
```

Options: `--threshold 0.9` (the production rule, max window score above the threshold,
applied to every detector), `--rule vendor` (each vendor's own AI label instead),
`--baseline-provenance pre_llm_term` (which human units form the false-positive baseline),
`--samples` and `--detectors` to filter, `--group-by model prompt` (rates per factor
value), `--pair-by topic` (human vs AI units sharing a factor value, as pairs).

Output: positive rate and mean scores by term, score distributions split into the
baseline and everything else, a threshold sweep (false-positive rate on the baseline
against positive rate elsewhere), pairwise scatter plots with a CSV of disagreements
linking to both vendors' reports, a per-case report of challenge cases with each
detector's verdict, a list of self-reported false positives a detector still flags (for
a human to confirm, never taken as truth), a slope chart for `--pair-by`, a wide CSV of
max scores, and `summary.md` with the tables.

### Readout

`readout.py` judges each detector by its own verdict on the human baseline and on each part
of the October 2026 challenge set, with the Dashboard's alert rule as an extra column, exact
95% intervals, recall at thresholds calibrated to flag a fixed share of the baseline, and the
term samples against those thresholds. It reads Open Pangram score files directly, and
writes markdown and JSON:

```sh
.venv/bin/python readout.py ~/detector_comparison_2026-10.csv \
    --open-pangram ~/open_pangram_roberta.csv ~/open_pangram_llama.csv \
    --markdown ~/detector_results/readout.md --json ~/detector_results/readout.json
```

Baseline texts that appear in more than one sample are counted once per detector.

### Cutover questions

`pangram_cutover.py` answers what changes for production alerting if the detector behind
`CheckRevisionWithPangram` moves from one registry key to another. It needs a sample built
by `BuildAiDetectionSampleFromRecentScores` (its units carry the production score and band
in `metadata`) and the production population per band, which defaults to the September
2026 preflight counts:

```sh
.venv/bin/python pangram_cutover.py ~/detector_comparison_2026-09.csv --out ~/detector_results/cutover \
    --old "Pangram 3" --new "Pangram 4" --recent-sample recent_2026_09 \
    --population low=12558 mid=770 high=1305 --checks-per-month 2400
```

Output: positive rate per production band for both detectors, reweighted into a projected
alert rate (and alerts per month when `--checks-per-month` is given); the old detector's
fresh score against the stored production score, which measures run-to-run noise; threshold
transitions (both positive, old only, new only, neither) per sample and old model version;
humanized-window counts and the score distribution per document label; words per window for
each detector; baseline false-positive rate per model version; and `cutover_summary.md`
with the tables.

## Adding a detector

1. A client class in `lib/` with `#inference(text)` returning the parsed response, raising
   a class listed in its vendor's `errors` when the call fails.
2. A parser in `lib/ai/` including `DetectorSummary` and implementing `summary_values`,
   `max_ai_likelihood`, `average_ai_likelihood` and `clean_result`.
3. A `check_type` constant on `RevisionAiScore` and one entry in `AiDetector::REGISTRY`,
   naming the vendor (and a per-detector credit estimator if billing differs from the
   vendor's default, as it does for Originality's allowance scans).

For a new vendor, add an `AiDetector::Vendor` as well: the admin page partial that renders
its raw result, its minimum input in words (nil if none), how it bills credits, how to read
its balance, and its error classes. All of those may be nil. The admin AI tools page, the
sample scorer and the export take everything from the registry; nothing else changes.
