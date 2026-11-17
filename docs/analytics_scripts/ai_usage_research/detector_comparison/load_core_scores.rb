# Local dev only: loads detector comparison rows exported from production with
# ExportDetectorComparisonScores into this copy, so new detectors' scores sit
# next to the ones already loaded. Units are matched by sample name and text hash
# (unit ids differ between production and local copies). Re-running replaces rows.
#   bin/rails runner \
#     docs/analytics_scripts/ai_usage_research/detector_comparison/load_core_scores.rb \
#     ~/detector_comparison_core_scores_2026-11.jsonl
require 'json'

path = ARGV.first || abort('usage: load_core_scores.rb <export.jsonl>')
units = AiDetectionSample.pluck(:sample_name, :text_sha256, :id)
                         .to_h { |name, sha, id| [[name, sha], id] }
counts = Hash.new(0)
File.foreach(path) do |line|
  row = JSON.parse(line)
  unit_id = units[[row['sample_name'], row['text_sha256']]]
  next counts[:unmatched] += 1 unless unit_id

  score = RevisionAiScore.find_or_initialize_by(sample_id: unit_id, check_type: row['check_type'])
  counts[score.new_record? ? :created : :replaced] += 1
  score.update!(avg_ai_likelihood: row['avg'], max_ai_likelihood: row['max'],
                details: row['details'], created_at: row['created_at'],
                check_origin: RevisionAiScore::DETECTOR_COMPARISON_ORIGIN)
end
pp counts
