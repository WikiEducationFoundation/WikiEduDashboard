# frozen_string_literal: true

require_dependency "#{Rails.root}/app/services/export_ai_detection_comparison"

# The data behind the admin detector comparison page: every unit of the
# known-AI samples (generated and Agpedia texts) and the human texts they are
# paired with, each with every detector's verdict and scores, plus each
# detector's verdicts on the pre-ChatGPT human baseline. Texts are left out;
# DescribeDetectorComparisonUnit serves one unit in full. Cached until a unit
# or a comparison score changes.
class SummarizeDetectorComparison
  PROVENANCES = [AiDetectionSample::SYNTHETIC, 'agpedia'].freeze
  RETIRED_SAMPLES = '%_retired'
  # The Dashboard's alert rule: any Pangram window scoring above this.
  ALERT_THRESHOLD = 0.9
  UNIT_COLUMNS = %i[id sample_name ground_truth provenance url word_count text_sha256 factors
                    metadata].freeze

  attr_reader :result

  def self.page_units
    AiDetectionSample.where(provenance: PROVENANCES)
                     .where.not('sample_name LIKE ?', RETIRED_SAMPLES)
  end

  def self.baseline_units
    AiDetectionSample.where(ground_truth: AiDetectionSample::HUMAN,
                            provenance: AiDetectionSample::PRE_LLM_TERM)
  end

  # Verdict and scores of one stored row, or nil for a failed call.
  def self.score_row(score)
    return if score.avg_ai_likelihood.nil?

    summary = ExportAiDetectionComparison.summary_for(score)
    row = { label: summary['label'], flagged: summary['label'] == 'AI',
            max: summary['max_score'], mean: summary['mean_window_score'],
            document: summary['document_score'], windows: summary['window_count'] }
    return row unless score.check_type.start_with?('Pangram')

    row.merge(alert: summary['max_score'].to_f > ALERT_THRESHOLD)
  end

  def initialize
    @result = Rails.cache.fetch(cache_key) { build }
  end

  private

  def cache_key
    scores = RevisionAiScore.where.not(sample_id: nil)
    ['detector_comparison', AiDetectionSample.count, AiDetectionSample.maximum(:updated_at),
     scores.count, scores.maximum(:updated_at)]
  end

  def build
    units = load(self.class.page_units)
    paired_ids = units.filter_map { |unit| unit.metadata['paired_unit_id'].presence&.to_i }
    pairs = load(self.class.baseline_units.where(id: paired_ids.uniq))
    { units: (units + pairs).map { |unit| unit_row(unit) },
      baseline: baseline, generated_at: Time.zone.now }
  end

  def load(scope)
    scope.select(UNIT_COLUMNS).includes(:revision_ai_scores).to_a
  end

  def unit_row(unit)
    { id: unit.id, sample: unit.sample_name, ground_truth: unit.ground_truth,
      provenance: unit.provenance, words: unit.word_count, url: unit.url,
      factors: unit.factors, condition: unit.metadata['condition'],
      paired_unit_id: unit.metadata['paired_unit_id'].presence&.to_i,
      scores: scores(unit) }
  end

  def scores(unit)
    unit.revision_ai_scores.to_h { |score| [score.check_type, self.class.score_row(score)] }.compact
  end

  # Each detector's verdicts on the baseline, counting each text once: some
  # samples repeat baseline texts.
  def baseline
    rows = load(self.class.baseline_units).flat_map do |unit|
      unit.revision_ai_scores.filter_map do |score|
        row = self.class.score_row(score)
        [unit.text_sha256, score.check_type, row] if row
      end
    end
    rows.uniq { |sha, check_type, _row| [sha, check_type] }
        .group_by { |_sha, check_type, _row| check_type }
        .transform_values { |group| tally(group.map(&:last)) }
  end

  def tally(rows)
    counts = { texts: rows.size, flagged: rows.count { |row| row[:flagged] } }
    return counts unless rows.first.key?(:alert)

    counts.merge(alerts: rows.count { |row| row[:alert] })
  end
end
