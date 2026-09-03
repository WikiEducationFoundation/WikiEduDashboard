# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/ai/detector_summary"
require_dependency "#{Rails.root}/lib/utils/wiki_url_parser"

# Loads the March 2026 detector comparison CSV (sampled cumulative diffs by
# term, scored with Pangram 3, Originality Turbo and Originality Academic) as an
# AiDetectionSample, including the scores it already holds, so that only new
# detectors need to be run on those units. Expected columns: term,
# cumulative_diff, and per detector the max/avg/result columns listed below.
class ImportDetectorComparisonCsv
  attr_reader :builder, :imported

  COLUMNS = {
    RevisionAiScore::PANGRAM_V3_KEY => {
      max: 'pangram_max_likelihood', avg: 'pangram_avg_likelihood',
      fraction_ai: 'pangram_fraction_ai', fraction_mixed: 'pangram_fraction_ai_assisted',
      fraction_human: 'pangram_fraction_human'
    },
    RevisionAiScore::ORIGINALITY_TURBO_KEY => {
      max: 'o_ai_turbo_max_fake', avg: 'o_ai_turbo_avg_fake',
      document: 'o_ai_turbo_ai_confidence', label: 'o_ai_turbo_result'
    },
    RevisionAiScore::ORIGINALITY_ACADEMIC_KEY => {
      max: 'o_ai_academic_max_fake', avg: 'o_ai_academic_avg_fake',
      document: 'o_ai_academic_ai_confidence', label: 'o_ai_academic_result'
    }
  }.freeze

  def initialize(sample_name:, path:, pangram_version: nil, verbose: false)
    @sample_name = sample_name
    @path = path
    @pangram_version = pangram_version
    @imported = 0
    @rows = CSV.read(path, headers: true)
    build_units(verbose)
    import_scores
  end

  private

  def build_units(verbose)
    rows = @rows.filter_map do |row|
      next if row['cumulative_diff'].blank?

      { url: row['cumulative_diff'], campaign_slug: row['term'],
        ground_truth: BuildAiDetectionSample.ground_truth_for_term(row['term']),
        metadata: { 'imported_from' => File.basename(@path) } }
    end
    @builder = BuildAiDetectionSampleFromUrls.new(sample_name: @sample_name, rows:, verbose:)
  end

  def import_scores
    @rows.each do |row|
      unit = unit_for(row['cumulative_diff'])
      next unless unit

      COLUMNS.each do |check_type, columns|
        import_score(unit, check_type, columns, row) if row[columns[:max]].present?
      end
    end
  end

  def unit_for(url)
    target = WikiUrlParser.new(url.to_s).revision_target
    return unless target

    AiDetectionSample.find_by(sample_name: @sample_name, rev_id: target[:rev_id],
                              from_rev_id: target[:from_rev])
  end

  def import_score(unit, check_type, columns, row)
    return if unit.revision_ai_scores.exists?(check_type:)

    RevisionAiScore.create!(sample_id: unit.id, revision_id: unit.rev_id, wiki_id: unit.wiki_id,
                            url: unit.url, check_type:,
                            check_origin: RevisionAiScore::DETECTOR_COMPARISON_ORIGIN,
                            max_ai_likelihood: number(row[columns[:max]]),
                            avg_ai_likelihood: number(row[columns[:document] || columns[:avg]]),
                            details: { 'summary' => summary(check_type, columns, row),
                                       'imported_from' => File.basename(@path) })
    @imported += 1
  end

  def summary(check_type, columns, row)
    pangram = check_type.start_with?('Pangram')
    values = { 'check_type' => check_type, 'vendor' => pangram ? 'pangram' : 'originality',
               'model_version' => (@pangram_version if pangram),
               'label' => label(row[columns[:label]]) }.merge(numeric_values(columns, row))
    DetectorSummary::KEYS.to_h { |key| [key, values[key]] }
  end

  NUMERIC_COLUMNS = { 'max_score' => :max, 'mean_window_score' => :avg,
                      'document_score' => :document, 'fraction_ai' => :fraction_ai,
                      'fraction_mixed' => :fraction_mixed,
                      'fraction_human' => :fraction_human }.freeze

  def numeric_values(columns, row)
    NUMERIC_COLUMNS.to_h { |key, column| [key, number(row[columns[column]])] }
  end

  def number(value)
    Float(value) if value.present?
  end

  # Originality's classification column holds 1 for AI and 0 for original text.
  def label(value)
    return if value.blank?

    value.to_i == 1 ? 'AI' : 'Original'
  end
end
