# requests to GPTZero API
class GptZeroApi
  def initialize
    @api_key = ENV['gpt_zero_api_key']
  end

  # see https://api.gptzero.me/v2/model-versions/ai-scan
  # This is the newest at the time of implementation.
  MODEL = '2025-05-02-base'
  API_URL = 'https://api.gptzero.me'
  def predict(text)
    conn = Faraday.new(
      url: API_URL,
      headers: {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'x-api-key' => @api_key
      }
    ) 

    response = conn.post('v2/predict/text') do |req| 
      req.body = { document: text, multilingual: false }.to_json
    end

    @response = response
    @result = JSON.parse response.body
    begin
      @sentences = @result['documents'].first['sentences']
    rescue
      puts @result
    end
  end

  THRESHOLD = 0.5
  def suspected_sentences
    @sentences.filter { |s| s['generated_prob'] > THRESHOLD }
  end

  def most_suspicious_sentence
    @most_suspicious_sentence ||= @sentences.max_by { |s| s['generated_prob'] }
  end

  def top_generated_prob
    most_suspicious_sentence['generated_prob']
  end

  def most_suspicious_sentence_text
    most_suspicious_sentence['sentence']
  end
end