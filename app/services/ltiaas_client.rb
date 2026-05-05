# frozen_string_literal: true

# Thin Faraday wrapper around the LTIAAS REST API.
#
# Centralizes:
#   - request authorization (LTIK launch token vs. service-auth bearer)
#   - timeouts
#   - error classification: 4xx authoritative, 401 auth, 429 rate limit,
#     5xx/network transient
#
# Two construction modes:
#
#   ltik mode (during a Canvas launch, 24h scope):
#     LtiaasClient.with_ltik(domain, api_key, ltik)
#
#   service mode (background jobs, no active launch):
#     LtiaasClient.with_service_auth(domain, service_auth_token)
#
# Sidekiq's built-in retry handles LtiaasTransientError/LtiaasRateLimitError;
# callers should let those propagate. LtiaasClientError and LtiaasAuthError
# are authoritative and should be handled (or surfaced) at the call site.
class LtiaasClient
  OPEN_TIMEOUT = 5
  TIMEOUT = 30

  def self.with_ltik(domain, api_key, ltik)
    new(domain:, auth_header: "LTIK-AUTH-V2 #{api_key}:#{ltik}")
  end

  # SERVICE-AUTH-V1 is LTIAAS's launch-independent auth scheme. The
  # service_key is retrieved from `idtoken.services.serviceKey` during a
  # launch and persisted on the LtiCourseBinding; it does not expire but
  # should be refreshed on every launch (the underlying NRPS/AGS endpoint
  # URLs may change). The api_key is the same long-lived account API key
  # used for LTIK auth.
  # See https://docs.ltiaas.com/guides/api/authentication
  def self.with_service_auth(domain, api_key, service_key)
    new(domain:, auth_header: "SERVICE-AUTH-V1 #{api_key}:#{service_key}")
  end

  def initialize(domain:, auth_header:)
    @domain = domain
    @auth_header = auth_header
    @conn = build_connection
  end

  def get(path)
    handle_response { @conn.get(path) }
  end

  def post(path, body)
    handle_response { @conn.post(path, body) }
  end

  def put(path, body)
    handle_response { @conn.put(path, body) }
  end

  def delete(path)
    handle_response { @conn.delete(path) }
  end

  private

  def build_connection
    Faraday.new(
      url: "https://#{@domain}",
      request: { timeout: TIMEOUT, open_timeout: OPEN_TIMEOUT }
    ) do |config|
      config.headers['Authorization'] = @auth_header
      config.request :json
      config.response :json, content_type: /\bjson$/
    end
  end

  def handle_response
    response = yield
    classify_failure(response) unless response.success?
    response.body
  rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
    raise LtiaasTransientError, "LTIAAS network failure: #{e.class}: #{e.message}"
  end

  def classify_failure(response)
    case response.status
    when 401, 403
      raise LtiaasAuthError.new(response.body, response.status)
    when 429
      raise LtiaasRateLimitError.new(response.body, response.status)
    when 500..599
      raise LtiaasTransientError, "LTIAAS #{response.status}: #{response.body}"
    else
      raise LtiaasClientError.new(response.body, response.status)
    end
  end

  class LtiaasClientError < StandardError
    attr_reader :response_body, :status_code

    def initialize(response_body, status_code)
      @response_body = response_body
      @status_code = status_code
      super("LTIAAS request failed (#{status_code}): #{response_body}")
    end
  end

  class LtiaasAuthError < LtiaasClientError; end
  class LtiaasRateLimitError < LtiaasClientError; end
  class LtiaasTransientError < StandardError; end
end
