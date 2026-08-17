# frozen_string_literal: true

require 'faraday'
require 'json'
require 'securerandom'

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
    # `offer: true` is the Canvas API's publish-on-create switch — it's
    # separate from `course[workflow_state]` and what students actually
    # check against. Without it the student sees "Not Yet Available —
    # This course has not been published by the instructor yet" even
    # with workflow_state 'available' set in the create body.
    post("/api/v1/accounts/#{@account_id}/courses",
         course: { name:, course_code:, workflow_state: 'available' }, offer: true)
  end

  def enroll_user(course_id:, user_id:, role:)
    post("/api/v1/courses/#{course_id}/enrollments",
         enrollment: { user_id:, type: role, enrollment_state: 'active' })
  end

  # Find (or create) a persistent, dedicated test user by login id, so a spec
  # can enroll a second student without a second credential set. The user never
  # logs in — it only needs to exist and be enrollable so the roster sync
  # discovers it. Reused across runs (matched by login id).
  def find_or_create_user(unique_id:, name:)
    match = get("/api/v1/accounts/#{@account_id}/users", search_term: unique_id)
            &.find { |u| u['login_id'] == unique_id }
    return match['id'] if match

    post("/api/v1/accounts/#{@account_id}/users",
         user: { name: },
         pseudonym: { unique_id:, password: SecureRandom.hex(16),
                      send_confirmation: false })['id']
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

  # Deep-link-created assignments (and the module a bulk import builds)
  # arrive unpublished — invisible to students until published.
  def publish_assignment(course_id:, assignment_id:)
    put("/api/v1/courses/#{course_id}/assignments/#{assignment_id}",
        'assignment[published]' => true)
  end

  def publish_all_modules(course_id:)
    (get("/api/v1/courses/#{course_id}/modules") || []).each do |mod|
      put("/api/v1/courses/#{course_id}/modules/#{mod['id']}",
          'module[published]' => true)
    end
  end

  def find_course(course_id:)
    get("/api/v1/courses/#{course_id}")
  end

  # AGS line items surface as Canvas assignments. Returns the full list
  # so a caller can match ours by `name` (which equals the line item's
  # label, e.g. "Wikipedia trainings" or "Wk1 Evaluate Wikipedia").
  def list_assignments(course_id:)
    get("/api/v1/courses/#{course_id}/assignments", per_page: 100)
  end

  # Convenience: find the assignment whose name matches a line item label.
  # Returns nil when no assignment carries that exact name yet (e.g. the
  # AGS line-item sync hasn't run).
  def find_assignment(course_id:, name:)
    list_assignments(course_id:).find { |a| a['name'] == name }
  end

  # A student's submission for one assignment, including the AGS score
  # and the score comment(s) carried alongside it. `user_id` is the
  # Canvas user id of the student. `include` takes extra Canvas include
  # values (e.g. 'submission_history') for callers that need the attempt
  # trail rather than just the current state.
  # The key is 'include', NOT 'include[]': Faraday's nested encoder adds the
  # brackets for an array value, so 'include[]' went out as `include[][]=...`,
  # which Canvas ignores. Every read through here came back with no
  # `submission_comments` key at all — making score comments look like they had
  # never reached Canvas when they were there the whole time.
  def submission(course_id:, assignment_id:, user_id:, include: [])
    params = { 'include' => ['submission_comments', *include] }
    get("/api/v1/courses/#{course_id}/assignments/#{assignment_id}/submissions/#{user_id}",
        params)
  end

  # Grade one submission the way an instructor would in SpeedGrader. The
  # question this exists for is what a later AGS PendingManual/no-score push
  # does to a grade that is already in place, and what matters for that is the
  # submission reaching workflow_state 'graded' with a score — which a REST
  # grade does, without the flakiness of driving SpeedGrader's UI. Canvas
  # records the token's owner as the grader either way.
  def grade_submission(course_id:, assignment_id:, user_id:, grade:)
    put("/api/v1/courses/#{course_id}/assignments/#{assignment_id}/submissions/#{user_id}",
        'submission[posted_grade]' => grade)
  end

  def assignment(course_id:, assignment_id:)
    get("/api/v1/courses/#{course_id}/assignments/#{assignment_id}")
  end

  # Show or hide the tool's tab in the course's Course Navigation. The
  # account tool's course_navigation placement can be default-disabled
  # (instructors opt in per course); the harvest also uses this to stage the
  # "before enabling" state so the enabling step reads truthfully. No-op when
  # the tab is already in the desired state or absent. The label defaults to
  # the current staging registration's tool name (no placement title is set);
  # override via CANVAS_TOOL_LABEL alongside LaunchHelpers#tool_label.
  def set_course_nav(course_id:, hidden:,
                     label: ENV.fetch('CANVAS_TOOL_LABEL', 'wikiedu.org testing'))
    tab = get("/api/v1/courses/#{course_id}/tabs").find { |t| t['label'] == label }
    return unless tab && tab['hidden'] != hidden

    put("/api/v1/courses/#{course_id}/tabs/#{tab['id']}", hidden: hidden)
  end

  # --- LTI registration inspection -------------------------------------------
  # Read-backs for the privacy-level check. The distinction these exist to make
  # is that the *installed tool* is what governs launch claims and the NRPS
  # roster, and it can differ from what the developer key's tool_configuration
  # asks for — which is exactly what happened when an admin chose "Anonymized"
  # in Canvas's Register App dialog.

  def list_developer_keys
    get("/api/v1/accounts/#{@account_id}/developer_keys")
  end

  # The privacy level the key's LTI configuration *asks* for. Canvas nests it
  # under the tool_configuration's Canvas extension.
  def developer_key_privacy_level(key_id)
    config = get("/api/lti/accounts/#{@account_id}/developer_keys/#{key_id}/tool_configuration")
    config.dig('tool_configuration', 'settings', 'extensions')
          &.first&.dig('privacy_level')
  end

  def list_external_tools
    get("/api/v1/accounts/#{@account_id}/external_tools", per_page: 100)
  end

  # The privacy level the installed tool actually uses.
  def external_tool_privacy_level(tool_id)
    get("/api/v1/accounts/#{@account_id}/external_tools/#{tool_id}")['privacy_level']
  end

  # Canvas's newer LTI-registration API, which the Apps page is built on. The
  # record carries an `account_binding` whose workflow_state is the availability
  # switch: flipping it to "on" is what deploys the ContextExternalTool. Until
  # then a dynamic registration has a developer key and no installed tool at all,
  # so there is nothing whose privacy_level can be read — "registering is not
  # installing", in the guide's terms.
  def list_lti_registrations
    get("/api/v1/accounts/#{@account_id}/lti_registrations", per_page: 100)['data']
  end

  def find_lti_registration_by_key(key_id)
    list_lti_registrations.find { |r| r['developer_key_id'].to_s == key_id.to_s }
  end

  # Creating a *deployment* is what makes the app available — the API equivalent of
  # the guide's "Make it available" step, and what brings a ContextExternalTool
  # (and so a readable privacy_level) into existence. A dynamic registration on its
  # own leaves the app installed-but-unavailable with no deployment at all.
  #
  # Found by probing, since the newer LTI-registration API isn't documented
  # alongside the old external_tools one:
  #   PUT  .../lti_registrations/:id/binding          404
  #   POST .../lti_registrations/:id/bind             422 "Dynamic Registrations
  #                                                        cannot be used as templates"
  #   POST .../developer_keys/:key/developer_key_account_bindings
  #                                                   201, but deploys nothing
  #   POST .../lti_registrations/:id/deployments      200 — this one
  def create_deployment(registration_id)
    post("/api/v1/accounts/#{@account_id}/lti_registrations/#{registration_id}/deployments")
  end

  def delete_deployment(registration_id, deployment_id)
    delete("/api/v1/accounts/#{@account_id}/lti_registrations/" \
           "#{registration_id}/deployments/#{deployment_id}")
  end

  def delete_lti_registration(registration_id)
    delete("/api/v1/accounts/#{@account_id}/lti_registrations/#{registration_id}")
  end

  def delete_developer_key(key_id)
    delete("/api/v1/developer_keys/#{key_id}")
  end

  def delete_external_tool(tool_id)
    delete("/api/v1/accounts/#{@account_id}/external_tools/#{tool_id}")
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

  def put(path, params = {})
    handle(@conn.put(path, params))
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
