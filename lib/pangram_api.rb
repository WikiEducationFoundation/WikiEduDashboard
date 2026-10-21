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

  attr_reader :result

  # Pangram version 2 got deprecated on 1st, April, 2026
  # V2_API_URL = 'https://text-extended.api.pangram.com'

  # Pangram 3 answers synchronously. It is scheduled for shutdown on 30 September 2026.
  V3_API_URL = 'https://text.api.pangram.com/v3'
  def self.v3
    new(api_url: V3_API_URL, options: { public_dashboard_link: true })
  end

  # Pangram 4 is only served through the asynchronous task endpoint:
  # POST /task returns a task_id, then GET /task/{task_id} is polled until
  # the stage is terminal. Results typically arrive within a few seconds.
  V4_API_URL = 'https://text.external-api.pangram.com/task'
  V4_MODEL = 'pangram-4'
  def self.v4
    new(api_url: V4_API_URL,
        options: { public_dashboard_link: true, model: V4_MODEL },
        async: true)
  end

  OPEN_TIMEOUT = 5 # seconds to establish a connection
  REQUEST_TIMEOUT = 30 # seconds per HTTP request
  POLL_INTERVAL = 0.5 # seconds between task status checks
  TASK_TIMEOUT = 60 # seconds to wait for an asynchronous task overall
  SUCCESS_STAGE = 'STAGE_SUCCESS'
  FAILED_STAGE = 'STAGE_FAILED'

  def initialize(api_url:, options:, async: false)
    @options = options
    @api_url = api_url
    @async = async
    @api_key = ENV['pangram_api_key']
  end

  # Returns the parsed inference result hash. Raises a PangramApi::Error subclass
  # when the API refuses the request or the task fails or times out.
  def inference(text)
    @result = @async ? async_inference(text) : sync_inference(text)
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

  def sync_inference(text)
    parse_response(post_text(text))
  end

  def async_inference(text)
    task_id = parse_response(post_text(text))['task_id']
    poll_task(task_id)
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

  def monotonic_now
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end
end
