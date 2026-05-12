# frozen_string_literal: true

require 'faraday'
require 'json'

# Thin wrapper around the Canvas REST API for provisioning + teardown of
# test-course state. Surface kept narrow to what the staging specs
# actually need; expand as more flows are exercised.
#
# Authentication: bearer token in `CANVAS_ADMIN_TOKEN`. The token must
# belong to a Canvas user with admin permissions on the
# `CANVAS_TEST_ACCOUNT_ID` account (usually root account on the staging
# Canvas).
#
# Method shape: returns parsed JSON Hash on success, raises ApiError
# with the Canvas-side error body on non-2xx so failures are
# self-diagnosing in the rspec output.
class CanvasApiClient
  class ApiError < StandardError
    attr_reader :status, :body
    def initialize(status:, body:, message: nil)
      @status = status
      @body = body
      super(message || "Canvas API #{status}: #{body}")
    end
  end

  class ConfigError < StandardError; end

  def initialize(token: ENV.fetch('CANVAS_ADMIN_TOKEN', nil),
                 base_url: ENV.fetch('CANVAS_BASE_URL', 'https://canvas.wikiedu.org'),
                 account_id: ENV.fetch('CANVAS_TEST_ACCOUNT_ID', nil))
    raise ConfigError, 'CANVAS_ADMIN_TOKEN is not set' if token.to_s.empty?
    raise ConfigError, 'CANVAS_TEST_ACCOUNT_ID is not set' if account_id.to_s.empty?

    @token = token
    @base_url = base_url
    @account_id = account_id
    @conn = build_conn
  end

  def create_course(name:, course_code: name)
    post("/api/v1/accounts/#{@account_id}/courses",
         course: { name:, course_code:, workflow_state: 'available' })
  end

  def enroll_user(course_id:, user_id:, role:)
    post("/api/v1/courses/#{course_id}/enrollments",
         enrollment: { user_id:, type: role, enrollment_state: 'active' })
  end

  # Adds the Wiki Education Dashboard external tool to the course's
  # Course Navigation. `tool_config` should mirror what's already in
  # the developer-key tool_configuration for the course_navigation
  # placement.
  def install_external_tool(course_id:, tool_config:)
    post("/api/v1/courses/#{course_id}/external_tools", tool_config)
  end

  def delete_course(course_id:)
    delete("/api/v1/courses/#{course_id}", event: 'delete')
  end

  def find_course(course_id:)
    get("/api/v1/courses/#{course_id}")
  end

  private

  def build_conn
    Faraday.new(url: @base_url) do |f|
      f.request :url_encoded
      f.headers['Authorization'] = "Bearer #{@token}"
      f.options.timeout = 30
      f.options.open_timeout = 5
    end
  end

  def get(path, params = {})
    handle(@conn.get(path, params))
  end

  def post(path, params = {})
    handle(@conn.post(path, params))
  end

  def delete(path, params = {})
    handle(@conn.delete(path) { |req| req.params = params })
  end

  def handle(response)
    body = response.body
    parsed = body.empty? ? nil : (JSON.parse(body) rescue body)

    if response.success?
      parsed
    else
      raise ApiError.new(status: response.status, body: parsed || body)
    end
  end
end
