# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/ai/detector_summary"

# Loads scores from a detector run outside the Dashboard, such as the Open
# Pangram models scored by analysis/score_open_pangram.py, so they sit beside
# the vendor scores. Rows name units by text_sha256 and carry the
# DetectorSummary keys; every unit with that text gets the score, in any
# sample. Importing a file again updates the rows it imported before. Rows that
# record a failed scoring run are skipped.
class ImportOfflineDetectorScores
  INTEGER_KEYS = %w[window_count windows_above_0_5 windows_above_0_9
                    humanized_window_count].freeze
  STRING_KEYS = %w[check_type vendor model_version label report_url].freeze

  attr_reader :imported, :unmatched

  def initialize(path:)
    @path = path
    @imported = 0
    @unmatched = 0
    import
  end

  private

  def import
    CSV.foreach(@path, headers: true) do |row|
      next if row['error'].present? || row['check_type'].blank?

      units = AiDetectionSample.where(text_sha256: row['text_sha256'])
      @unmatched += 1 if units.empty?
      units.each { |unit| import_score(unit, row) }
    end
  end

  def import_score(unit, row)
    summary = summary(row)
    score = RevisionAiScore.find_or_initialize_by(sample_id: unit.id, check_type: row['check_type'])
    score.update!(revision_id: unit.rev_id, wiki_id: unit.wiki_id, url: unit.url,
                  check_origin: RevisionAiScore::DETECTOR_COMPARISON_ORIGIN,
                  max_ai_likelihood: summary['max_score'],
                  avg_ai_likelihood: summary['document_score'] || summary['mean_window_score'],
                  details: { 'summary' => summary, 'scored_at' => row['scored_at'],
                             'imported_from' => File.basename(@path) })
    @imported += 1
  end

  def summary(row)
    DetectorSummary::KEYS.to_h { |key| [key, typed(key, row[key])] }
  end

  def typed(key, value)
    return if value.blank?
    return value if STRING_KEYS.include?(key)

    INTEGER_KEYS.include?(key) ? Integer(Float(value)) : Float(value)
  end
end
