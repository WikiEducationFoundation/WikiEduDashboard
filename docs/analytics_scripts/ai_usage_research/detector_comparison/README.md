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

Pangram is billed per word at a rate we can afford at scale. Originality.ai is not:
its credit balance is small, it bills about one credit per 100 words per check, and an
AI Allowance scan bills roughly double. Keep Originality to small curated samples
(around 100 units), run at most two Originality checks per unit, and always dry-run
first. Each AI Allowance threshold is a separate scan whose block scores differ, so a
threshold cannot be re-derived offline from another threshold's result; the two we use
are 15 (Originality's default) and 40 (their minimize-false-positives setting).

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
detectors = [RevisionAiScore::PANGRAM_V4_KEY, RevisionAiScore::ORIGINALITY_AI_ALLOWANCE_15_KEY, RevisionAiScore::ORIGINALITY_AI_ALLOWANCE_40_KEY]
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
your machine for analysis.

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
