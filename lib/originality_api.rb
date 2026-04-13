# frozen_string_literal: true

# requests to Originality.ai Inference API

# API docs: https://docs.originality.ai/originality-ai-api-v1
class OriginalityApi
  attr_reader :result

  API_URL = 'https://api.originality.ai/api/v3/scan'

  # Originality Models descriptions:
  # Very hard to bypass (higher False Positive rate).
  # Use when you want to be certain AI was not used
  TURBO_MODEL = 'turbo'
  # Ideal for teachers and students.
  # Accurate for STEM answers (Code and Formulas).
  ACADEMIC_MODEL = 'academic'
  # Ideal when some use of AI for editing is allowed.
  # Best for academia.
  LITE_MODEL = 'lite'
  # Latest Beta Version of the Lite Model
  LITE_BETA_MODEL = 'lite-102'


  def self.turbo
    new(model: TURBO_MODEL)
  end

  def self.academic
    new(model: ACADEMIC_MODEL)
  end

  def self.lite
    new(model: LITE_MODEL)
  end

  def self.lite_beta
    new(model: LITE_BETA_MODEL)
  end

  def initialize(model:)
    @model = model
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

  private

  def base_request_body(text)
    {
      check_ai: true,
      check_plagiarism: false,
      check_facts: false,
      check_readability: false,
      check_grammar: false,
      check_contentOptimizer: false,
      storeScan: true,
      aiModelVersion: @model,
      content: text
    }
  end
end
