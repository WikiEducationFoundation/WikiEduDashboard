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
  # (spec/staging/support/dashboard_admin_client.rb) uses it to seed a gradebook
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

  # POST /api/lineitems/{urlencoded(lineitem_id)}/scores — submits a
  # student's score on one line item. Per LTIAAS docs (and LTI Advantage
  # AGS), `userId`, `activityProgress`, `gradingProgress` are required.
  # `scoreGiven` and `scoreMaximum` come together when the score should
  # update the gradebook. `comment` is a free-form text field surfaced in the
  # Canvas gradebook; we put a lateness marker and the Dashboard's origin there,
  # and deliberately never a sandbox URL — those embed the student's Wikipedia
  # username and a gradebook comment is visible to anyone with gradebook access
  # (see LtiBlockProgress).
  # 204 No Content on success.
  # See https://docs.ltiaas.com/guides/api/manipulating-grades/
  # rubocop:disable Metrics/ParameterLists
  def post_score(lineitem_id:, user_lti_id:, score_given:, score_maximum: 1.0,
                 comment: nil, activity_progress: 'Completed',
                 grading_progress: 'FullyGraded', timestamp: Time.current)
    body = {
      userId: user_lti_id,
      scoreGiven: score_given,
      scoreMaximum: score_maximum,
      activityProgress: activity_progress,
      gradingProgress: grading_progress,
      timestamp: timestamp.iso8601
    }
    body[:comment] = comment if comment.present?
    @client.post("/api/lineitems/#{CGI.escape(lineitem_id)}/scores", body)
  end
  # rubocop:enable Metrics/ParameterLists

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
