# Writes one row per detector comparison core text and detector, for the November 2026
# analysis (round_2026_11.py). The core texts are the comparison page's units: the
# known-human texts and the topics dataset. Scores come through
# CollectDetectorComparisonScores, so a result stored on an identical copy of a text counts.
# Each row carries the unit's group and factors and the detector's DetectorSummary.
#   bin/rails runner \
#     docs/analytics_scripts/ai_usage_research/detector_comparison/analysis/export_core_table.rb \
#     ~/detector_results_2026-11/core_table.csv
require 'csv'

path = File.expand_path(ARGV.first || abort('usage: export_core_table.rb <out.csv>'))
known_human_ids = SummarizeKnownHumanTexts.units.pluck(:id).to_set
units = (SummarizeKnownHumanTexts.units.select(SummarizeDetectorComparison::UNIT_COLUMNS)
                                 .includes(:revision_ai_scores).to_a +
         SummarizeDetectorComparison.units).uniq(&:id)
scores = CollectDetectorComparisonScores.new(units).result

def group_for(unit, known_human)
  return 'known_human' if known_human
  return 'agpedia' if unit.provenance == 'agpedia'
  return 'article_version' if SummarizeDetectorComparison::ARTICLE_VERSIONS.include?(unit.provenance)
  return 'paired_human' unless unit.provenance == AiDetectionSample::SYNTHETIC
  return 'open_weight_ladder' if unit.sample_name.include?('ladder')

  base = %w[one_line detailed].include?(unit.metadata['condition'].to_s)
  base ? 'base_prompts' : 'other_strategies'
end

summary_keys = DetectorSummary::KEYS - %w[check_type report_url]
columns = %w[unit_id text_sha256 group sample_name ground_truth word_count condition model topic
             era vendor tier runner web_searches web_fetches steps_per_turn
             check_type flagged alert] + summary_keys
count = 0
CSV.open(path, 'w') do |csv|
  csv << columns
  units.each do |unit|
    base = [unit.id, unit.text_sha256, group_for(unit, known_human_ids.include?(unit.id)),
            unit.sample_name, unit.ground_truth, unit.word_count, unit.metadata['condition'],
            unit.factors['model'], unit.factors['topic'], unit.factors['era'],
            unit.factors['vendor'], unit.factors['tier'], unit.metadata['runner'],
            unit.metadata['web_searches'], unit.metadata['web_fetches'],
            unit.metadata['steps_per_turn']]
    scores[unit.id].each do |score|
      next if score.avg_ai_likelihood.nil?

      summary = ExportAiDetectionComparison.summary_for(score)
      alert = score.check_type.start_with?('Pangram') ? summary['max_score'].to_f > 0.9 : nil
      flagged = SummarizeDetectorComparison.flagged?(summary['label'])
      csv << base + [score.check_type, flagged, alert] + summary_keys.map { |key| summary[key] }
      count += 1
    end
  end
end
puts "#{units.size} units, #{count} scored rows -> #{path}"
