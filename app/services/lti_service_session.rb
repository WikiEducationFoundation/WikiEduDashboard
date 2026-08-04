# frozen_string_literal: true

# Service-auth LTIAAS session for background work: reading the roster over NRPS
# (fetch_memberships), reading the gradebook's line items over AGS
# (list_line_items), and posting scores at them (post_score). Distinct from
# LtiSession, which is launch-scoped and uses LTIK auth.
#
# Construct with an LtiCourseBinding; the binding holds the persisted LTIAAS
# service-auth credentials, in plain text — see the
# CreateLtiCourseBindings migration for why, and
# docs/canvas_integration_todos.md for the pre-production dependency that
# tracks it.
class LtiServiceSession
  attr_reader :binding

  def initialize(binding)
    @binding = binding
    @client = LtiaasClient.with_service_auth(
      ENV['LTIAAS_DOMAIN'],
      ENV['LTIAAS_API_KEY'],
      binding.ltiaas_service_credentials
    )
  end

  # Fetch the LMS course roster via NRPS, paginating through all pages.
  # Returns an array of member hashes with normalized keys — deliberately
  # PII-free (see normalize_member):
  #   { user_lti_id, roles: [...], status: 'Active' | 'Inactive' | 'Deleted' }
  # See https://docs.ltiaas.com/api/get-memberships/
  def fetch_memberships(role: nil)
    members = []
    path = role ? "/api/memberships?role=#{CGI.escape(role)}" : '/api/memberships'
    loop do
      response = @client.get(path)
      members.concat(Array(response['members']).map { |m| normalize_member(m) })
      next_url = response['next']
      break if next_url.blank?

      path = "/api/memberships?url=#{CGI.escape(next_url)}"
    end
    members
  end

  # POST /api/lineitems — creates a new gradebook line item.
  # Returns the lineitem `id` (a URL string) which we persist on
  # LtiLineItem.lineitem_id for later score calls.
  # See https://docs.ltiaas.com/guides/api/manipulating-grade-lines/
  #
  # The runtime never calls this: deep-link-first means Canvas creates every
  # column when the instructor imports, and SyncLtiLineItems only discovers them.
  # It stays because the live-Canvas screenshot harness
  # (staging_specs/support/dashboard_admin_client.rb) uses it to seed a gradebook
  # deterministically instead of driving the Modules picker through a browser.
  def upsert_line_item(label:, tag: nil, score_maximum: 1.0, resource_link_id: nil,
                       resource_id: nil, end_date_time: nil, launch_url: nil)
    body = { label:, scoreMaximum: score_maximum }
    body[:tag] = tag if tag.present?
    body[:resourceLinkId] = resource_link_id if resource_link_id.present?
    body[:resourceId] = resource_id if resource_id.present?
    body[:endDateTime] = end_date_time.iso8601 if end_date_time.present?
    # Canvas-only AGS extension, passed through verbatim by LTIAAS: makes the
    # created assignment an external_tool one that launches `launch_url`,
    # instead of a bare no-submission gradebook column. Without it, students
    # get no tool view at all from the assignment page.
    if launch_url.present?
      body['https://canvas.instructure.com/lti/submission_type'] =
        { type: 'external_tool', external_tool_url: launch_url }
    end
    response = @client.post('/api/lineitems', body)
    response['id']
  end

  # No update_line_item / delete_line_item here on purpose. Canvas owns a column
  # once the instructor has imported it: we never rename one (renaming a block
  # updates the local row's label only) and never delete one, because deleting
  # from LTIAAS destroys the Canvas gradebook column and its scores — a stale
  # column is soft-archived locally instead. Both verbs existed for the
  # auto-creating gradebook layouts and went unused once those were dropped.

  # GET /api/lineitems[?resourceLinkId=&tag=&...] — paginated.
  def list_line_items(resource_link_id: nil, tag: nil)
    items = []
    path = base_lineitems_path(resource_link_id, tag)
    loop do
      response = @client.get(path)
      items.concat(Array(response['lineItems']))
      next_url = response['next']
      break if next_url.blank?

      path = "/api/lineitems?url=#{CGI.escape(next_url)}"
    end
    items
  end

  # POST /api/lineitems/{urlencoded(lineitem_id)}/scores — reports one
  # student's result on one line item. Per LTIAAS docs (and LTI Advantage
  # AGS), `userId`, `activityProgress`, `gradingProgress` are required.
  # `comment` is a free-form text field surfaced in the Canvas gradebook; we put
  # the Dashboard's origin there, and deliberately never a sandbox URL — those
  # embed the student's Wikipedia username and a gradebook comment is visible to
  # anyone with gradebook access (see LtiBlockProgress).
  #
  # `score_given` is optional, and omitting it is a distinct, deliberate signal
  # rather than a degenerate case: AGS requires scoreMaximum only alongside a
  # score, and Canvas leaves the submission ungraded when a PendingManual result
  # arrives without one ("the assignment will not be graded" — its Score docs;
  # `reset_score?` in Canvas's scores_controller skips grade submission). That is
  # how instructor-evaluated work reaches Canvas as "submitted, please grade"
  # instead of as marks the Dashboard never awarded. See SyncLtiGrades.
  # 204 No Content on success.
  # See https://docs.ltiaas.com/guides/api/manipulating-grades/
  # rubocop:disable Metrics/ParameterLists
  def post_score(lineitem_id:, user_lti_id:, score_given: nil, score_maximum: 1.0,
                 comment: nil, activity_progress: 'Completed',
                 grading_progress: 'FullyGraded', timestamp: Time.current,
                 submission_url: nil)
    body = {
      userId: user_lti_id,
      activityProgress: activity_progress,
      gradingProgress: grading_progress,
      timestamp: timestamp.iso8601
    }
    # Both together or neither: a scoreMaximum with no scoreGiven would assert a
    # denominator for a grade that isn't being reported.
    body.merge!(scoreGiven: score_given, scoreMaximum: score_maximum) unless score_given.nil?
    body[:comment] = comment if comment.present?
    body[SUBMISSION_CLAIM] = submission_payload(submission_url) if submission_url
    @client.post("/api/lineitems/#{CGI.escape(lineitem_id)}/scores", body)
  end
  # rubocop:enable Metrics/ParameterLists

  # Canvas's own extension to the AGS Score payload. Without it a score arrives
  # with no submitted artifact behind it, and Canvas answers an instructor who
  # opens the student's submission with a bare "No Preview Available".
  # `basic_lti_launch` + a URL is how a tool says "the work is here, launch me for
  # it"; Canvas stores the URL as the submission's own and renders it in
  # SpeedGrader. Verified field names against Canvas's scores_controller
  # (SCORE_SUBMISSION_TYPES, and submission_data becoming the submission URL).
  SUBMISSION_CLAIM = 'https://canvas.instructure.com/lti/submission'

  # `new_submission: true` is not optional, however much a re-post shouldn't be a
  # new attempt: Canvas only stores `submission_data` when the score claims a new
  # submission. Verified on staging — with false, the submission existed but its
  # url was nil and an instructor still got "No Preview Available"; with true the
  # url appeared and the attempt incremented.
  #
  # Which is why the caller sends this only on the FIRST push for a
  # (column, student) — see SyncLtiGrades#post_for_grading. One attempt each,
  # carrying the URL, and nothing to pile up afterwards.
  def submission_payload(url)
    { new_submission: true, submission_type: 'basic_lti_launch', submission_data: url }
  end

  private

  def base_lineitems_path(resource_link_id, tag)
    params = {}
    params[:resourceLinkId] = resource_link_id if resource_link_id.present?
    params[:tag] = tag if tag.present?
    return '/api/lineitems' if params.empty?

    "/api/lineitems?#{params.to_query}"
  end

  # Anonymized posture: we deliberately keep only the opaque LTI user id, the
  # roles (needed to tell staff from students), and the membership status. Names,
  # emails, and pictures the roster may carry are dropped here so no Canvas PII
  # enters the Dashboard — identity comes from the student's own Wikipedia OAuth.
  def normalize_member(member)
    {
      user_lti_id: member['userId'],
      roles: Array(member['roles']),
      status: member['status']
    }
  end
end
