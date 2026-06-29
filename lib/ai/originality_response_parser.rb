# frozen_string_literal: true

class OriginalityResponseParser
  def initialize(version, response)
    @version = version
    @response = response
  end

  # Method for compatibility with Pangram
  def max_ai_likelihood
    fake_confidence_blocks.max
  end

  # Method for compatibility with Pangram
  def average_ai_likelihood
    @response['results']['ai']['confidence']['AI']
  end

  def fake_confidence_blocks
    @response['results']['ai']['blocks'].map { |block| block['result']['fake']}
  end

  # Deletes text field from the originality response to avoid storing that into the db
  def clean_result
    result = @response.dup

    result['results']['properties'].delete('content')
    result['results']['properties'].delete('formattedContent')

    blocks = result['results']['ai']['blocks']
    if blocks.is_a?(Array)
      result['results']['ai']['blocks'] = blocks.map { |w| w.except('text') }
    end
    result
  end
end
