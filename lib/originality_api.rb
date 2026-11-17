# frozen_string_literal: true

# requests to Originality.ai Inference API
#
# API docs: https://docs.originality.ai/ (rendered client-side; https://docs.originality.ai/llms.txt
# and https://docs.originality.ai/scan.md are readable). The behavior described below
# was verified against the live API on 2026-09-03 (classic models) and 2026-11-17 (5.0).
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
  # silently fell back to the default model instead of erroring (2026-09), so this
  # guards against storing results under the wrong check_type.
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
  REQUEST_TIMEOUT = 120 # seconds per request; 5.0 Max is the slower model

  # Originality.ai 5.0 models, released 2026-11-09. The classic models (Turbo,
  # Academic, Lite) are deprecated and AI Allowance mode retires on 2026-12-11.
  # Observed 2026-11-17: both bill about one credit per 100 words through the API,
  # although Originality's pricing page lists Max at ten times that.
  MODEL_5 = 'model-5.0'
  MODEL_5_MAX = 'model-5.0-max' # Originality's highest-accuracy setting; slower
  # Scans are stored in the account under this title.
  SCAN_TITLE = 'Wiki Education Dashboard'

  def self.model_5
    new(model: MODEL_5)
  end

  def self.model_5_max
    new(model: MODEL_5_MAX)
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

  def initialize(model:)
    @model = model
  end

  # The identifier the API is expected to echo back in results.ai.model.
  def expected_model
    @model
  end

  # Returns the parsed scan result hash. Raises an OriginalityApi::Error subclass
  # when the text is too short, the API refuses the request, or it ran a
  # different model than requested.
  def inference(text)
    words = text.to_s.split.size
    raise TextTooShort, "#{words} words; Originality requires #{MIN_WORDS}" if words < MIN_WORDS

    response = connection.post('') { |req| req.body = request_body(text).to_json }
    result = parse_response(response)
    verify_model!(result)
    @result = result
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
    { title: SCAN_TITLE,
      content: text,
      aiModelVersion: @model,
      check_ai: true,
      check_plagiarism: false,
      check_facts: false,
      check_readability: false,
      check_grammar: false,
      check_contentOptimizer: false,
      storeScan: true }
  end

  def parse_response(response)
    raise RequestError.new(response.status, response.body) unless response.success?

    parsed = JSON.parse(response.body)
    raise RequestError.new(response.status, parsed['message']) if parsed['error']

    parsed
  end

  # A result without a model id is a failed scan (for example an error object in
  # results.ai), not a model change, so it fails this one call only.
  def verify_model!(result)
    actual = result.dig('results', 'ai', 'model')
    raise RequestError.new(200, result.dig('results', 'ai')) if actual.nil?
    return if actual == expected_model

    raise ModelMismatch, "requested #{expected_model} but Originality ran #{actual.inspect}"
  end
end
