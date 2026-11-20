# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/ai/ai_detector"

# Writes the detector comparison rows of the given detectors, one JSON object per
# line, for loading into a local copy with
# docs/analytics_scripts/ai_usage_research/detector_comparison/load_core_scores.rb.
# Units are identified by sample name and text hash, since unit ids differ
# between copies. Details are stored without text, so the file holds scores only.
#   ExportDetectorComparisonScores.new('/home/sage/detector_comparison_core_scores.jsonl').count
class ExportDetectorComparisonScores
  attr_reader :count

  def initialize(path, check_types: AiDetector.keys)
    @path = path
    @check_types = check_types
    @count = 0
    export
  end

  private

  def export
    File.open(@path, 'w') do |file|
      RevisionAiScore.where(check_origin: RevisionAiScore::DETECTOR_COMPARISON_ORIGIN,
                            check_type: @check_types)
                     .includes(:sample).find_each do |score|
        file.puts row(score).to_json
        @count += 1
      end
    end
  end

  def row(score)
    { sample_name: score.sample&.sample_name, text_sha256: score.sample&.text_sha256,
      check_type: score.check_type, avg: score.avg_ai_likelihood,
      max: score.max_ai_likelihood, details: score.details,
      created_at: score.created_at.iso8601 }
  end
end
