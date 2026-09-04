# frozen_string_literal: true

# requests to Originality.ai Inference API
#
# API docs: https://docs.originality.ai/ (rendered client-side). The parameter
# behavior described below was verified against the live API on 2026-09-03.
class OriginalityApi
  class Error < StandardError; end

  # The API answered with a non-success HTTP status, or a 200 carrying an error payload.
  class RequestError < Error
    attr_reader :status

    def initialize(status, body)
      @status = status
      super("Originality API returned HTTP #{status}: #{body.to_s[0, 200]}")
    end
  end

  # The API ran a different model than requested. Unknown aiModelVersion values
  # silently fall back to the default model instead of erroring, so this guards
  # against storing results under the wrong check_type.
  class ModelMismatch < Error; end

  # Originality refuses to score fewer than MIN_WORDS words.
  class TextTooShort < Error; end

  attr_reader :result

  API_URL = 'https://api.originality.ai/api/v3/scan'
  # Only the v1 path answers this; the v3 path returns HTML.
  CREDIT_BALANCE_URL = 'https://api.originality.ai/api/v1/account/credits/balance'
  MIN_WORDS = 50
  WORDS_PER_CREDIT = 100 # roughly; observed 90 words → 1 credit, 135 words → 2 per check
  OPEN_TIMEOUT = 5 # seconds to establish a connection
  REQUEST_TIMEOUT = 60 # seconds per request

  # Classic models, selected with aiModelVersion. As of 2026-09-03 these are
  # Turbo 3.0.2, Academic 0.0.5 and Lite 1.0.2 (https://originality.ai/blog/ai-accuracy).
  # 'lite' is also accepted but it is undocumented which version it maps to.
  TURBO_MODEL = 'turbo' # Strict zero-tolerance policies; highest false positive rate
  ACADEMIC_MODEL = 'academic' # Tuned for student writing, including STEM
  LITE_102_MODEL = 'lite-102' # Allows light AI editing; the API default

  # AI Allowance mode is selected with check_ai_allowance + ai_allowance_threshold
  # instead of aiModelVersion. Higher thresholds tolerate more AI-assisted text;
  # Originality describes 40 as the setting for minimizing false positives.
  # Each threshold is scored separately, so results cannot be re-thresholded offline.
  AI_ALLOWANCE_THRESHOLDS = [0, 5, 15, 25, 40].freeze

  def self.turbo
    new(model: TURBO_MODEL)
  end

  def self.academic
    new(model: ACADEMIC_MODEL)
  end

  def self.lite_102
    new(model: LITE_102_MODEL)
  end

  def self.ai_allowance(threshold:)
    new(allowance_threshold: threshold)
  end

  # Remaining credits on the account. Roughly one credit per 100 words per check.
  def self.credit_balance
    response = Faraday.new(headers: api_headers).get(CREDIT_BALANCE_URL)
    raise RequestError.new(response.status, response.body) unless response.success?

    JSON.parse(response.body)['balance']
  end

  def self.api_headers
    { 'Content-Type' => 'application/json',
      'X-OAI-API-KEY' => ENV['originality_api_key'],
      'User-Agent' => "#{ENV['dashboard_url']} #{Rails.env}" }
  end

  def initialize(model: nil, allowance_threshold: nil)
    unless model || allowance_threshold
      raise ArgumentError, 'specify a model or an allowance threshold'
    end
    if allowance_threshold && !AI_ALLOWANCE_THRESHOLDS.include?(allowance_threshold)
      raise ArgumentError, "allowance threshold must be one of #{AI_ALLOWANCE_THRESHOLDS}"
    end

    @model = model
    @allowance_threshold = allowance_threshold
  end

  # The identifier the API is expected to echo back in results.ai.aiModel.
  def expected_model
    @allowance_threshold ? "allowance-#{@allowance_threshold}%" : @model
  end

  # Returns the parsed scan result hash. Raises an OriginalityApi::Error subclass
  # when the text is too short, the API refuses the request, or it ran a
  # different model than requested.
  def inference(text)
    words = text.to_s.split.size
    raise TextTooShort, "#{words} words; Originality requires #{MIN_WORDS}" if words < MIN_WORDS

    response = connection.post('') { |req| req.body = request_body(text).to_json }
    @result = parse_response(response)
    verify_model!
    @result
  end

  private

  def connection
    @connection ||= Faraday.new(
      url: API_URL,
      headers: self.class.api_headers,
      request: { open_timeout: OPEN_TIMEOUT, timeout: REQUEST_TIMEOUT }
    )
  end

  def request_body(text)
    body = { check_ai: true,
             check_plagiarism: false,
             check_facts: false,
             check_readability: false,
             check_grammar: false,
             check_contentOptimizer: false,
             storeScan: true,
             content: text }
    return body.merge(aiModelVersion: @model) unless @allowance_threshold

    body.merge(check_ai_allowance: true, ai_allowance_threshold: @allowance_threshold)
  end

  def parse_response(response)
    raise RequestError.new(response.status, response.body) unless response.success?

    parsed = JSON.parse(response.body)
    raise RequestError.new(response.status, parsed['message']) if parsed['error']

    parsed
  end

  def verify_model!
    actual = @result.dig('results', 'ai', 'aiModel')
    return if actual == expected_model

    raise ModelMismatch, "requested #{expected_model} but Originality ran #{actual.inspect}"
  end
end
