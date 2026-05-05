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

  def upsert_line_item(label:, tag: nil, score_maximum: 1.0, due_date: nil, resource_id: nil)
    _ = [label, tag, score_maximum, due_date, resource_id]
    raise NotImplementedError, 'upsert_line_item lands in PR 4 (line-item sync)'
  end

  def update_line_item(_lineitem_id, _attrs)
    raise NotImplementedError, 'update_line_item lands in PR 4 (line-item sync)'
  end

  def delete_line_item(_lineitem_id)
    raise NotImplementedError, 'delete_line_item lands in PR 4 (line-item sync)'
  end

  def list_line_items
    raise NotImplementedError, 'list_line_items lands in PR 4 (line-item sync)'
  end

  # rubocop:disable Metrics/ParameterLists
  def post_score(lineitem_id:, user_lti_id:, score_given:, score_maximum: 1.0,
                 comment: nil, activity_progress: 'Completed',
                 grading_progress: 'FullyGraded', timestamp: Time.current)
    _ = [lineitem_id, user_lti_id, score_given, score_maximum, comment,
         activity_progress, grading_progress, timestamp]
    raise NotImplementedError, 'post_score lands in PR 5 (grade sync)'
  end
  # rubocop:enable Metrics/ParameterLists

  private

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
