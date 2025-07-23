# requests to pangram.com Inference API
class PangramApi
  attr_reader :result
  def initialize
    @api_key = ENV['pangram_api_key']
  end

  SLIDING_WINDOW_URL = 'https://text-sliding.api.pangramlabs.com'
  def inference(text)
    conn = Faraday.new(
      url: SLIDING_WINDOW_URL,
      headers: {'Content-Type' => 'application/json', 'x-api-key' => @api_key }
    ) 

    response = conn.post('') do |req| 
      req.body = { text: text }.to_json
    end
    puts response
    @response = response
    @result = JSON.parse @response.body
  end

  def ai_likelihood
    @result['ai_likelihood']
  end

  def average_ai_likelihood
    @result['avg_ai_likelihood']
  end

  def max_ai_likelihood
    @result['max_ai_likelihood']
  end

  def fraction_ai_content
    @result['fraction_ai_content']
  end

  def predicted_ai_window_count
    @result['window_likelihoods'].count { |likelihood| likelihood > 0.5 }
  end

  def predicted_llm
    return nil if fraction_ai_content.zero?
    @result['llm_prediction'].key(@result['llm_prediction'].values.max)
  end
end