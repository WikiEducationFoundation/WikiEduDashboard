# frozen_string_literal: true

# requests to pangram.com Inference API

# API docs: https://pangram.readthedocs.io/en/stable/api/rest.html
# Pangram 4 migration guide: https://www.pangram.com/blog/pangram-4-migration-guide
class PangramApi
  class Error < StandardError; end

  # The API answered with a non-success HTTP status (bad request, exhausted credits, outage).
  class RequestError < Error
    attr_reader :status

    def initialize(status, body)
      @status = status
      super("Pangram API returned HTTP #{status}: #{body.to_s[0, 200]}")
    end
  end

  # The asynchronous task reached a terminal failure stage.
  class TaskFailed < Error; end

  # The asynchronous task did not finish within TASK_TIMEOUT.
  class TaskTimeout < Error; end

  # The API answered with a different model version than the client was pinned to.
  # pangram-4 has changed version without notice (4.0 to 4.1 on 2026-10-19), so a
  # pinned client refuses the result rather than store it under the wrong key.
  class ModelMismatch < Error; end

  attr_reader :result

  # Pangram 2 was deprecated on 1 April 2026 and Pangram 3 (synchronous,
  # https://text.api.pangram.com/v3) shut down on 30 September 2026.

  # Pangram 4 is only served through the asynchronous task endpoint:
  # POST /task returns a task_id, then GET /task/{task_id} is polled until
  # the stage is terminal. Results typically arrive within a few seconds.
  # pangram-4 cannot be pinned to a version; pass expected_version to refuse
  # results from any other one.
  V4_API_URL = 'https://text.external-api.pangram.com/task'
  V4_MODEL = 'pangram-4'
  def self.v4(expected_version: nil)
    new(api_url: V4_API_URL, options: { public_dashboard_link: true, model: V4_MODEL },
        expected_version:)
  end

  OPEN_TIMEOUT = 5 # seconds to establish a connection
  REQUEST_TIMEOUT = 30 # seconds per HTTP request
  POLL_INTERVAL = 0.5 # seconds between task status checks
  TASK_TIMEOUT = 60 # seconds to wait for an asynchronous task overall
  SUCCESS_STAGE = 'STAGE_SUCCESS'
  FAILED_STAGE = 'STAGE_FAILED'

  attr_reader :expected_version

  def initialize(api_url:, options:, expected_version: nil)
    @options = options
    @api_url = api_url
    @expected_version = expected_version
    @api_key = ENV['pangram_api_key']
  end

  # Returns the parsed inference result hash. Raises a PangramApi::Error subclass
  # when the API refuses the request, the task fails or times out, or the result
  # comes from a version other than expected_version.
  # One client is shared by every thread of a process (AiDetector memoizes it), so
  # the result is kept in a local variable; @result is only a convenience for
  # single-threaded callers.
  def inference(text)
    task_id = parse_response(post_text(text))['task_id']
    result = poll_task(task_id)
    verify_version!(result)
    @result = result
  end

  private

  def connection
    @connection ||= Faraday.new(
      url: @api_url,
      headers: { 'Content-Type' => 'application/json',
                 'x-api-key' => @api_key,
                 'User-Agent' => "#{ENV['dashboard_url']} #{Rails.env}" },
      request: { open_timeout: OPEN_TIMEOUT, timeout: REQUEST_TIMEOUT }
    )
  end

  def post_text(text)
    connection.post('') do |req|
      req.body = @options.merge({ text: }).to_json
    end
  end

  def poll_task(task_id)
    deadline = monotonic_now + TASK_TIMEOUT
    loop do
      sleep POLL_INTERVAL
      result = parse_response(connection.get("#{@api_url}/#{task_id}"))
      return result if result['stage'] == SUCCESS_STAGE
      raise TaskFailed, failure_message(task_id, result) if result['stage'] == FAILED_STAGE
      raise TaskTimeout, timeout_message(task_id) if monotonic_now > deadline
    end
  end

  def failure_message(task_id, result)
    "Pangram task #{task_id} failed: #{result['error'] || result['stage']}"
  end

  def timeout_message(task_id)
    "Pangram task #{task_id} unfinished after #{TASK_TIMEOUT}s"
  end

  def parse_response(response)
    raise RequestError.new(response.status, response.body) unless response.success?

    JSON.parse(response.body)
  end

  def verify_version!(result)
    return if @expected_version.nil? || result['version'] == @expected_version

    actual = result['version'].inspect
    raise ModelMismatch, "expected Pangram #{@expected_version} but the API answered as #{actual}"
  end

  def monotonic_now
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end
end
