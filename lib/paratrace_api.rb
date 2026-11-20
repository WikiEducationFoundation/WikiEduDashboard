# frozen_string_literal: true

# Requests to the ParaTrace AI text detection API.
#
# API docs: https://paratrace.net/api. Verified against the live API on 2026-11-18:
# POST /v1/api/detect is synchronous and returns the detector version plus one
# document per text; GET /v1/api/account reports the credit balance. A credit
# covers 512 tokens of the detector's tokenizer (about 400 English words) per
# text, minimum one. Failed and refused requests are not charged; a 503 is refunded.
class ParatraceApi
  class Error < StandardError; end

  # The API answered with a non-success HTTP status. Bodies are {"detail": "..."}.
  class RequestError < Error
    attr_reader :status

    def initialize(status, body)
      @status = status
      super("ParaTrace API returned HTTP #{status}: #{body.to_s[0, 200]}")
    end
  end

  # The API answered with a different detector version than the client was pinned to.
  class ModelMismatch < Error; end

  attr_reader :result

  API_URL = 'https://api.paratrace.net/v1/api'
  # The default operating point, and the one ParaTrace's published figures use.
  OPERATING_POINT = 'strict'
  TOKENS_PER_CREDIT = 512
  # Tokens per word of the detector's tokenizer on our texts: 27,785 tokens for
  # 19,912 words over 20 core texts (2026-11-18). Used only to estimate credits.
  TOKENS_PER_WORD = 1.4
  OPEN_TIMEOUT = 5 # seconds to establish a connection
  REQUEST_TIMEOUT = 120 # seconds per request; texts run to tens of thousands of characters

  def self.v10
    new(expected_version: 'v10-ft-g')
  end

  # Remaining credits on the account.
  def self.credit_balance
    response = connection.get('account')
    raise RequestError.new(response.status, response.body) unless response.success?

    JSON.parse(response.body)['credits_remaining']
  end

  def self.connection
    Faraday.new(url: "#{API_URL}/",
                headers: { 'Content-Type' => 'application/json',
                           'Authorization' => "Bearer #{ENV['paratrace_api_key']}",
                           'User-Agent' => "#{ENV['dashboard_url']} #{Rails.env}" },
                request: { open_timeout: OPEN_TIMEOUT, timeout: REQUEST_TIMEOUT })
  end

  def initialize(expected_version: nil)
    @expected_version = expected_version
  end

  attr_reader :expected_version

  # Returns the parsed response for one text. Raises a ParatraceApi::Error
  # subclass when the API refuses the request or answers as another version.
  # The result is kept in a local variable because one client is shared by every
  # thread of a process (AiDetector memoizes it).
  def inference(text)
    response = connection.post('detect') do |req|
      req.body = { text:, operating_point: OPERATING_POINT }.to_json
    end
    raise RequestError.new(response.status, response.body) unless response.success?

    result = JSON.parse(response.body)
    verify_version!(result)
    @result = result
  end

  private

  def connection
    @connection ||= self.class.connection
  end

  def verify_version!(result)
    return if @expected_version.nil? || result['detector_version'] == @expected_version

    actual = result['detector_version'].inspect
    raise ModelMismatch, "expected ParaTrace #{@expected_version} but the API answered as #{actual}"
  end
end
