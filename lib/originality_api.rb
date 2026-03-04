# frozen_string_literal: true

# requests to Originality.ai Inference API

# API docs: https://docs.originality.ai/originality-ai-api-v1
class OriginalityApi
  attr_reader :result
  
  API_URL = 'https://api.originality.ai/api/v3/scan'

  def initialize
    @api_key = ENV['originality_api_key']
  end

  def inference(text)
    conn = Faraday.new(
      url: API_URL,
      headers: { 'Content-Type' => 'application/json', 'X-OAI-API-KEY' => @api_key }
    )
    conn.headers['User-Agent'] = ENV['dashboard_url'] + ' ' + Rails.env

    response = conn.post('') do |req|
      req.body = base_request_body(text).to_json
    end

    @response = response
    @result = JSON.parse @response.body
  end

  def base_request_body(text)
    {
      check_ai: true,
      check_plagiarism: false,
      check_facts: false,
      check_readability: false,
      check_grammar: false,
      check_contentOptimizer: false,
      storeScan: true,
      aiModelVersion: "turbo",
      content: text
    }
  end
end
