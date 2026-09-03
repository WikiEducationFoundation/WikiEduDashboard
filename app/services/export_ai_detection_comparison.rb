# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/ai/ai_detector"

# Exports detector comparison results in long format: one row per
# (sample unit, detector), with the unit's identity and ground truth followed
# by the DetectorSummary keys. Summaries are derived from the stored raw
# response, or taken from details['summary'] for rows imported from a CSV.
# Long format keeps the analysis side independent of which detectors exist.
class ExportAiDetectionComparison
  UNIT_COLUMNS = %w[sample_name unit_id wiki rev_id from_rev_id diff_mode url campaign_slug
                    namespace ground_truth word_count text_sha256 metadata].freeze
  SCORE_COLUMNS = %w[score_id scored_at error].freeze

  def self.headers
    UNIT_COLUMNS + SCORE_COLUMNS + DetectorSummary::KEYS
  end

  attr_reader :rows

  def initialize(sample_names: nil)
    units = AiDetectionSample.includes(:wiki, :revision_ai_scores).order(:id)
    units = units.where(sample_name: sample_names) if sample_names
    @rows = units.flat_map { |unit| unit_rows(unit) }
  end

  # Returns the CSV as a string, and writes it to path when one is given.
  def to_csv(path = nil)
    headers = self.class.headers
    csv = CSV.generate do |out|
      out << headers
      rows.each { |row| out << headers.map { |header| row[header] } }
    end
    File.write(path, csv) if path
    csv
  end

  private

  def unit_rows(unit)
    unit.revision_ai_scores.sort_by(&:id).map do |score|
      unit_columns(unit).merge(score_columns(score))
    end
  end

  def unit_columns(unit)
    { 'sample_name' => unit.sample_name, 'unit_id' => unit.id, 'wiki' => unit.wiki&.domain,
      'rev_id' => unit.rev_id, 'from_rev_id' => unit.from_rev_id, 'diff_mode' => unit.diff_mode,
      'url' => unit.url, 'campaign_slug' => unit.campaign_slug, 'namespace' => unit.namespace,
      'ground_truth' => unit.ground_truth, 'word_count' => unit.word_count,
      'text_sha256' => unit.text_sha256, 'metadata' => unit.metadata.to_json }
  end

  def score_columns(score)
    columns = { 'score_id' => score.id, 'scored_at' => score.created_at,
                'check_type' => score.check_type }
    return columns.merge('error' => score.details['message']) if score.avg_ai_likelihood.nil?

    columns.merge(summary_for(score))
  end

  def summary_for(score)
    return score.details['summary'] if score.details['summary']

    parser_class = AiDetector.parser_class_for(score.check_type)
    return {} unless parser_class

    parser_class.new(score.check_type, score.details).summary
  end
end
