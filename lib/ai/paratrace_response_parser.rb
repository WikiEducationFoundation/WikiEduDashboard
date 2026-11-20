# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/ai/detector_summary"

# Reads a ParaTrace /v1/api/detect response for one text. The response has the
# detector version and a list of documents; a single-text request has one:
#   probability   0–1 whole-text probability (null if nothing is left after cleaning)
#   verdict       'human', 'mixed' or 'ai' (null if nothing is left after cleaning)
#   ai_fraction   share of the text labelled AI
#   category      'human', 'ai_assisted' or 'ai_generated'
#   windows       [{ start, end, probability, band }] in code points
#   segments      [{ start, end, label, probability, band }], merged runs of windows
# The response holds no text, so nothing is stripped before storage.
class ParatraceResponseParser
  include DetectorSummary

  # Verdicts in the spelling the rest of the comparison uses.
  LABELS = { 'human' => 'Human', 'mixed' => 'Mixed', 'ai' => 'AI' }.freeze

  def initialize(version, response)
    @version = version
    @response = response
  end

  def document
    @response['documents'].first
  end

  def detector_version
    @response['detector_version']
  end

  def label
    raw = document['verdict']
    LABELS.fetch(raw.to_s, raw)
  end

  # ParaTrace's whole-text probability. For texts of several windows its verdict
  # comes from the windows, not from this number.
  def document_score
    document['probability']
  end

  def max_ai_likelihood
    window_scores.max
  end

  # Method for compatibility with Pangram, as for Originality: the whole-text figure.
  def average_ai_likelihood
    document_score
  end

  def mean_window_score
    return if window_scores.empty?

    window_scores.sum.fdiv(window_scores.count)
  end

  def window_scores
    Array(document['windows']).map { |window| window['probability'] }
  end

  def clean_result
    @response
  end

  private

  def summary_values
    { 'check_type' => @version, 'vendor' => 'paratrace', 'model_version' => detector_version,
      'label' => label, 'document_score' => document_score,
      'max_score' => max_ai_likelihood, 'mean_window_score' => mean_window_score,
      'window_count' => window_scores.count,
      'windows_above_0_5' => window_scores.count { |score| score > 0.5 },
      'windows_above_0_9' => window_scores.count { |score| score > 0.9 },
      'fraction_ai' => document['ai_fraction'] }
  end
end
