# frozen_string_literal: true

# Represents a single LTI 1.3 launch from an LMS (currently Canvas, via
# LTIAAS). Active for the duration of one HTTP request that began with a
# Canvas click; uses launch-bound LTIK auth.
#
# Background jobs that need NRPS or AGS without an active launch should use
# LtiServiceSession instead.
class LtiSession
  INSTRUCTOR_ROLES = [
    'membership#Administrator',
    'membership#Instructor',
    'membership#Mentor'
  ].freeze

  attr_reader :idtoken

  def initialize(ltiaas_domain, api_key, ltik)
    @client = LtiaasClient.with_ltik(ltiaas_domain, api_key, ltik)
    @idtoken = @client.get('/api/idtoken')
  end

  def user_lti_id
    @idtoken['user']['id']
  end

  def user_name
    @idtoken['user']['name']
  end

  def user_email
    @idtoken['user']['email']
  end

  def user_roles
    @idtoken['user']['roles'] || []
  end

  def instructor?
    user_roles.any? do |str|
      INSTRUCTOR_ROLES.any? { |suffix| str.end_with?(suffix) }
    end
  end

  def student?
    !instructor?
  end

  # Backwards-compatible alias for callers still on the old name.
  alias user_is_teacher? instructor?

  def lms_id
    @idtoken['platform']['id']
  end

  def lms_family
    @idtoken['platform']['productFamilyCode']
  end

  def lms_context_id
    @idtoken['launch']['context']['id']
  end

  def lms_resource_link_id
    @idtoken['launch']['resourceLink']['id']
  end

  def context_title
    @idtoken['launch']['context']['title']
  end

  # LTI 1.3 / LTIAAS surfaces the platform's public base URL on the
  # `platform` claim. Defensive `dig` because LTIAAS payload shape is
  # documented but not formally verified against staging yet; a missing
  # value just means the status component renders without a clickable
  # link.
  def platform_url
    @idtoken.dig('platform', 'url')
  end

  def nrps_url
    @idtoken.dig('services', 'namesAndRoles', 'contextMembershipsUrl')
  end

  def ags_lineitems_url
    @idtoken.dig('services', 'assignmentAndGrades', 'lineItemsUrl') ||
      @idtoken.dig('services', 'assignmentAndGrades', 'lineitemsUrl')
  end

  # The single line-item URL for the assignment this launch came from. Per
  # LTIAAS docs this is `lineItemId` on the AGS service object, "present
  # only if there's only one line item ID associated with the current
  # context" — i.e. an assignment-context launch (the assignment_view
  # placement), not the course-navigation launch. We match it against
  # LtiLineItem#lineitem_id to identify which gradebook column was clicked,
  # then backfill `canvas_assignment_id` for fast lookups on later launches.
  # Older/alternate casings kept as a defensive fallback.
  def ags_lineitem_url
    @idtoken.dig('services', 'assignmentAndGrades', 'lineItemId') ||
      @idtoken.dig('services', 'assignmentAndGrades', 'lineItemUrl') ||
      @idtoken.dig('services', 'assignmentAndGrades', 'lineitemUrl')
  end

  # Canvas variable substitutions configured on the `assignment_view`
  # placement (custom_fields) arrive under the idtoken `custom` claim.
  # Blank on launches from placements that don't set them (e.g. the
  # course-navigation launch).
  def canvas_assignment_id
    @idtoken.dig('custom', 'canvas_assignment_id').presence
  end

  # Whether this deep-linking launch's placement accepts more than one
  # content item (Canvas: true from the Modules-page bulk placement, false
  # from assignment_selection). The processed idtoken omits the
  # deep-linking-settings claim, so this reads the raw JWT claims via a
  # second, lazy LTIAAS fetch. Defaults to single-item on any failure —
  # the mode every placement accepts.
  def accepts_multiple_content_items?
    settings = raw_idtoken['https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings']
    settings.present? && settings['accept_multiple'].to_s == 'true'
  rescue StandardError
    false
  end

  # The deep-link resource marker (e.g. "Block:42" or "TrainingProgress") we
  # set on the content item, echoed back under the `custom` claim on launches
  # of the Canvas assignment created from it. Lets the first such launch bind
  # its line item to the Dashboard gradable. Blank on launches of assignments
  # we didn't create via deep linking.
  def deep_link_resource
    @idtoken.dig('custom', 'resource').presence
  end

  # The service-auth key captured from this launch's idtoken. Long-lived
  # but per LTIAAS docs should be refreshed into the binding on every
  # launch in case the underlying NRPS/AGS endpoint URLs have changed.
  # See https://docs.ltiaas.com/guides/api/authentication
  def service_key
    @idtoken.dig('services', 'serviceKey')
  end

  # Looks up or creates the LtiCourseBinding for this launch. The binding's
  # `course_id` is left nil; the controller's setup flow populates it once
  # the instructor links to or creates a Dashboard course. Snapshot fields
  # (service_key, NRPS/AGS URLs, lms_family) are refreshed on every launch
  # so background-job credentials track the most recent launch.
  def find_or_create_binding!
    binding = LtiCourseBinding.find_or_initialize_by(
      lms_id:,
      lms_context_id:,
      lms_resource_link_id:
    )
    binding.lms_family = lms_family
    binding.lms_context_title = context_title
    binding.lms_platform_url = platform_url
    binding.nrps_url = nrps_url
    binding.ags_lineitems_url = ags_lineitems_url
    binding.ltiaas_service_credentials = service_key if service_key.present?
    binding.save!
    binding
  end

  # The binding whose Dashboard course is linked to this launch's Canvas
  # course (context), if any. Unlike find_or_create_binding!, this resolves
  # by context alone, not the full (lms_id, context, resource_link) identity:
  # a deep-linking-request launch arrives with no resource link of its own,
  # so the picker has to find the bound course by which Canvas course it came
  # from. Returns nil when the instructor hasn't linked a course yet.
  def bound_binding
    LtiCourseBinding.where(lms_id:, lms_context_id:)
                    .where.not(course_id: nil).first
  end

  # Idempotently records that `current_user` is the Dashboard user for this
  # LMS identity within the binding. Updates NRPS-supplied profile fields
  # (email/name/roles) on each launch so they stay fresh.
  def link_lti_user(current_user, binding: nil)
    binding ||= find_or_create_binding!
    context = LtiContext.find_or_initialize_by(
      user_lti_id:,
      lti_course_binding_id: binding.id
    )
    apply_context_attributes(context, current_user)
    context.linked_at ||= Time.current
    context.save!
    context
  end

  private

  def raw_idtoken
    @raw_idtoken ||= @client.get('/api/idtoken?raw=true')
  end

  def apply_context_attributes(context, current_user)
    context.user = current_user
    context.lms_id = lms_id
    context.lms_family = lms_family
    context.context_id = legacy_context_id
    context.email = user_email
    context.name = user_name
    context.roles = user_roles
  end

  # The legacy concatenated identifier persisted on the existing
  # `lti_contexts.context_id` column. Retained until the column is dropped
  # in a follow-up PR.
  def legacy_context_id
    "#{lms_context_id}::#{lms_resource_link_id}"
  end
end
