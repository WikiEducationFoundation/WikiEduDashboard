# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/ai/detector_summary"

# Reads an Originality.ai v3 scan response.
#
# With a classic model (aiModelVersion) the AI check is under results.ai.
# In AI Allowance mode the API also puts the allowance result under results.ai
# (aiModel echoes e.g. "allowance-15%") and repeats it under
# results.aiAllowance[threshold], so results.ai is read uniformly.
class OriginalityResponseParser
  include DetectorSummary

  def initialize(version, response)
    @version = version
    @response = response
  end

  def ai_result
    @response['results']['ai']
  end

  # Model identifier the API reports having used, e.g. 'turbo' or 'allowance-40%'.
  def ai_model
    ai_result['aiModel']
  end

  def ai_classified?
    ai_result['classification']['AI'] == 1
  end

  def label
    ai_classified? ? 'AI' : 'Original'
  end

  # Whole-text probability that the text is AI, as Originality reports it.
  def document_score
    ai_result['confidence']['AI']
  end

  # Method for compatibility with Pangram: the highest block score.
  def max_ai_likelihood
    window_scores.max
  end

  # Method for compatibility with Pangram. This is Originality's whole-text
  # confidence rather than the mean of block scores; see #mean_window_score.
  def average_ai_likelihood
    document_score
  end

  def mean_window_score
    window_scores.sum.fdiv(window_scores.count)
  end

  def window_scores
    ai_result['blocks'].map { |block| block['result']['fake'] }
  end
  alias fake_confidence_blocks window_scores

  def report_url
    @response.dig('results', 'properties', 'publicLink')
  end

  # Deletes text fields from the response to avoid storing them in the db.
  # Does not modify the original response.
  def clean_result
    result = @response.deep_dup
    result['results']['properties']&.delete('content')
    result['results']['properties']&.delete('formattedContent')
    result['results']['ai']['blocks'] = strip_text(result['results']['ai']['blocks'])
    result['results']['aiAllowance']&.each_value do |allowance|
      allowance['blocks'] = strip_text(allowance['blocks']) if allowance.is_a?(Hash)
    end
    result
  end

  private

  def strip_text(blocks)
    return blocks unless blocks.is_a?(Array)

    blocks.map { |block| block.except('text') }
  end

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
