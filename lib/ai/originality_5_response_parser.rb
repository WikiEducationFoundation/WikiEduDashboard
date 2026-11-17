# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/ai/detector_summary"

# Reads an Originality.ai 5.0 or 5.0 Max scan response. The AI result is under
# results.ai with a different shape from the classic models (see
# OriginalityResponseParser, which still reads rows stored before 2026-11):
#   model                 'model-5.0' or 'model-5.0-max'
#   prediction_label      'human', 'mixed' or (presumably) 'ai'
#   ai_assisted_percent   0–100, the share of the text Originality judges AI-assisted
#   sentences             [{ start_index, end_index, text, ai_score }], paragraph-sized
#                         segments despite the name
class Originality5ResponseParser
  include DetectorSummary

  # Verdicts in the spelling the rest of the comparison uses. Labels Originality
  # adds later pass through unchanged, so they still count as detections.
  LABELS = { 'human' => 'Human', 'mixed' => 'Mixed', 'ai' => 'AI' }.freeze

  def initialize(version, response)
    @version = version
    @response = response
  end

  def ai_result
    @response['results']['ai']
  end

  # Model identifier the API reports having used, e.g. 'model-5.0'.
  def ai_model
    ai_result['model']
  end

  def label
    raw = ai_result['prediction_label']
    LABELS.fetch(raw.to_s.downcase, raw)
  end

  # Share of the text Originality judges AI-assisted, as a fraction.
  def document_score
    ai_result['ai_assisted_percent']&.fdiv(100)
  end

  # Method for compatibility with Pangram: the highest segment score.
  def max_ai_likelihood
    window_scores.max
  end

  # Method for compatibility with Pangram. As for the classic models, this is
  # Originality's whole-text figure rather than the mean of segment scores.
  def average_ai_likelihood
    document_score
  end

  def mean_window_score
    return if window_scores.empty?

    window_scores.sum.fdiv(window_scores.count)
  end

  def segments
    ai_result['sentences'] || []
  end

  def window_scores
    segments.map { |segment| segment['ai_score'] }
  end

  def report_url
    @response.dig('results', 'properties', 'publicLink')
  end

  # Deletes text fields from the response to avoid storing them in the db.
  # Does not modify the original response.
  def clean_result
    result = @response.deep_dup
    result['results']['properties']&.delete('content')
    result['results']['properties']&.delete('formattedContent')
    ai = result['results']['ai']
    ai['sentences'] = ai['sentences'].map { |segment| segment.except('text') } if ai['sentences']
    result
  end

  private

  def summary_values
    { 'check_type' => @version, 'vendor' => 'originality', 'model_version' => ai_model,
      'label' => label, 'document_score' => document_score,
      'max_score' => max_ai_likelihood, 'mean_window_score' => mean_window_score,
      'window_count' => window_scores.count,
      'windows_above_0_5' => window_scores.count { |score| score > 0.5 },
      'windows_above_0_9' => window_scores.count { |score| score > 0.9 },
      'report_url' => report_url }
  end
end
