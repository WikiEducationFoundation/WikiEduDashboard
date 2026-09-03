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
  exact text sent to detectors, where it came from (wiki, revision, diff), the term,
  and a `ground_truth` label when we know how the text was produced
  (`human_pre_llm`, `self_reported_ai`, `self_reported_no_ai`, `experiment_ai`).
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

Alerts whose student answered the follow-up questionnaire (self-report becomes ground truth):

```ruby
BuildAiDetectionSampleFromAlertFollowups.new(sample_name: 'followups', since: 1.year.ago, verbose: true).summary
```

The March 2026 method, cumulative course diffs of substantial articles per term:

```ruby
BuildAiDetectionSampleFromArticlesByTerm.new(sample_name: 'terms_2026_09', terms: %w[spring_2022 fall_2025 spring_2026], per_term: 50, verbose: true).summary
```

Any list of diff or revision URLs, or a CSV with a URL column:

```ruby
BuildAiDetectionSampleFromUrls.new(sample_name: 'curated', rows: [{ url: 'https://en.wikipedia.org/w/index.php?diff=1315039613&oldid=1310000000', ground_truth: 'experiment_ai' }])
BuildAiDetectionSampleFromUrls.from_csv(sample_name: 'wvs_neu', path: 'docs/analytics_scripts/wvs_neu_ai_edits/dataset.csv', url_column: 'diff_url', ground_truth: 'experiment_ai', verbose: true)
```

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

## 4. Analyze

```sh
cd docs/analytics_scripts/ai_usage_research/detector_comparison/analysis
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
.venv/bin/python analyze.py ~/detector_comparison_2026-09.csv --out ~/detector_results
```

Options: `--threshold 0.9` (the production rule, max window score above the threshold,
applied to every detector), `--rule vendor` (each vendor's own AI label instead),
`--baseline human_pre_llm`, `--samples` and `--detectors` to filter.

Output: positive rate and mean scores by term, score distributions split into the
pre-LLM baseline and everything else, a threshold sweep (false-positive rate on the
baseline against positive rate elsewhere), pairwise scatter plots with a CSV of
disagreements linking to both vendors' reports, a wide CSV of max scores, and
`summary.md` with the tables.

## Adding a detector

1. A client class in `lib/` with `#inference(text)` returning the parsed response.
2. A parser in `lib/ai/` including `DetectorSummary` and implementing `summary_values`,
   `max_ai_likelihood`, `average_ai_likelihood` and `clean_result`.
3. A `check_type` constant on `RevisionAiScore` and one entry in `AiDetector::REGISTRY`.

The admin AI tools page, the sample scorer and the export pick it up from the registry.
