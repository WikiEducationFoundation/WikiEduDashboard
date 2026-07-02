# frozen_string_literal: true

# Service-auth LTIAAS session for background work (NRPS roster sync, AGS
# line-item management, AGS score posting). Distinct from LtiSession, which
# is launch-scoped and uses LTIK auth.
#
# Construct with an LtiCourseBinding; the binding holds the persisted
# LTIAAS service-auth credentials (encrypted before any real population).
#
# This is a v1-PR-1 skeleton: the actual NRPS/AGS verbs are stubbed and
# raise NotImplementedError. Implementations land in subsequent PRs:
#   - fetch_memberships         => PR 3 (roster sync)
#   - upsert_line_item, etc.    => PR 4 (line-item sync)
#   - post_score                => PR 5 (grade sync)
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
  # Returns an array of member hashes with normalized keys:
  #   { user_lti_id, name, email, given_name, family_name, picture,
  #     roles: [...], status: 'Active' | 'Inactive' | 'Deleted' }
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
  # LtiLineItem.lineitem_id for later PUT/score calls.
  # See https://docs.ltiaas.com/guides/api/manipulating-grade-lines/
  def upsert_line_item(label:, tag: nil, score_maximum: 1.0,
                       resource_link_id: nil, resource_id: nil, end_date_time: nil)
    body = { label:, scoreMaximum: score_maximum }
    body[:tag] = tag if tag.present?
    body[:resourceLinkId] = resource_link_id if resource_link_id.present?
    body[:resourceId] = resource_id if resource_id.present?
    body[:endDateTime] = end_date_time.iso8601 if end_date_time.present?
    response = @client.post('/api/lineitems', body)
    response['id']
  end

  # PUT /api/lineitems/{urlencoded(lineitem_id)} — replaces the line
  # item's metadata. label and scoreMaximum are required by LTIAAS.
  def update_line_item(lineitem_id, label:, score_maximum: 1.0)
    @client.put(
      "/api/lineitems/#{CGI.escape(lineitem_id)}",
      label:, scoreMaximum: score_maximum
    )
  end

  # DELETE /api/lineitems/{urlencoded(lineitem_id)}.
  # v1 grade-sync policy never calls this (we soft-archive locally
  # instead, since deleting from LTIAAS destroys the corresponding
  # Canvas gradebook column and its scores). Kept available for
  # admin tooling.
  def delete_line_item(lineitem_id)
    @client.delete("/api/lineitems/#{CGI.escape(lineitem_id)}")
  end

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
  # update the gradebook. `comment` is a free-form text field surfaced in
  # the Canvas gradebook (we use it for sandbox URLs and lateness flags).
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

  def normalize_member(member)
    {
      user_lti_id: member['userId'],
      name: member['name'],
      email: member['email'],
      given_name: member['givenName'],
      family_name: member['familyName'],
      picture: member['picture'],
      roles: Array(member['roles']),
      status: member['status']
    }
  end
end
