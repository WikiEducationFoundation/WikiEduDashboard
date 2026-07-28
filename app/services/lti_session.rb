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

  # Stands in for the resource link id on a deep-linking request, which has
  # none. Context-scoped by the binding's unique index, so one row per Canvas
  # course rather than one per picker visit.
  DEEP_LINKING_RESOURCE_LINK_ID = 'lti:deep-linking-request'

  attr_reader :idtoken

  def initialize(ltiaas_domain, api_key, ltik)
    @client = LtiaasClient.with_ltik(ltiaas_domain, api_key, ltik)
    @idtoken = @client.get('/api/idtoken')
  end

  def user_lti_id
    @idtoken['user']['id']
  end

  # Anonymized posture: the Dashboard never reads the launch's name/email (the
  # tool is registered so Canvas doesn't send them, and we don't consume them
  # even if a platform did). Identity comes from the student's Wikipedia OAuth.

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

  # A deep-linking request carries no resource link of its own, so fall back
  # to a synthetic, context-stable key: the launch still needs a binding row
  # to hang a course off when the instructor links from the picker's
  # break-out flow (the only linking entry point when the course-navigation
  # tab is off). Reading it unguarded used to raise NoMethodError there.
  def lms_resource_link_id
    @idtoken.dig('launch', 'resourceLink', 'id').presence || DEEP_LINKING_RESOURCE_LINK_ID
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

  # Looks up or creates the LtiCourseBinding for this launch. A binding models a
  # Canvas *course*, so it is keyed on (lms_id, lms_context_id) alone — every
  # launch from that Canvas course, whether nav, assignment or deep-link, and
  # whether before or after linking, resolves to the same row. Keying on the
  # resource link as well used to mint a throwaway row per assignment: the
  # student's LtiContext landed somewhere grade sync never reads, the bound
  # row's service credentials went stale, and a pre-link course could end up
  # with several rows competing to be the bound one.
  #
  # `course_id` stays nil until the controller's setup flow populates it.
  # Snapshot fields (service_key, NRPS/AGS URLs, lms_family, resource link) are
  # refreshed on every launch so background-job credentials track the most
  # recent launch.
  def find_or_create_binding!
    binding = LtiCourseBinding.find_or_initialize_by(lms_id:, lms_context_id:)
    binding.lms_resource_link_id = lms_resource_link_id
    binding.lms_family = lms_family
    binding.lms_context_title = context_title
    binding.lms_platform_url = platform_url
    binding.nrps_url = nrps_url
    binding.ags_lineitems_url = ags_lineitems_url
    binding.ltiaas_service_credentials = service_key if service_key.present?
    binding.save!
    binding
  end

  # This launch's binding, but only once it has a Dashboard course — callers use
  # it as "is this Canvas course linked yet?" and rely on the nil. Unlike
  # find_or_create_binding! it never creates a row, so a read-only path (the
  # anonymous launch views, the deep-link picker) can ask without side effects.
  # The (lms_id, lms_context_id) key is unique, so this is at most one row.
  def bound_binding
    LtiCourseBinding.where(lms_id:, lms_context_id:)
                    .where.not(course_id: nil).first
  end

  # Idempotently records that `current_user` is the Dashboard user for this
  # LMS identity within the binding. Refreshes the launch's roles each time
  # so they stay current; no name or email is read (anonymized posture).
  def link_lti_user(current_user, binding: nil)
    binding ||= find_or_create_binding!
    context = LtiContext.find_or_initialize_by(
      user_lti_id:,
      lti_course_binding_id: binding.id
    )
    reject_duplicate_user_link!(context, current_user, binding)
    log_identity_move(context, current_user)
    apply_context_attributes(context, current_user)
    context.linked_at ||= Time.current
    context.save!
    context
  end

  # Raised when the launching Dashboard user is already the linked identity for
  # a *different* LMS member of the same course. Callers turn this into the
  # "couldn't enroll you" view rather than a 500.
  class DuplicateUserLinkError < StandardError; end

  private

  # One Dashboard user per LMS course. Two Canvas identities linked to a single
  # Wikipedia account would make grade sync post the same progress at both
  # students' gradebook rows, so the second link is refused instead of silently
  # duplicating credit. A unique index enforces the same thing; this is the path
  # that makes it a handled error.
  def reject_duplicate_user_link!(context, current_user, binding)
    conflicts = LtiContext.where(lti_course_binding_id: binding.id,
                                 user_id: current_user.id)
    conflicts = conflicts.where.not(id: context.id) if context.persisted?
    return unless conflicts.exists?

    raise DuplicateUserLinkError,
          "user #{current_user.id} is already linked to another LMS identity " \
          "in binding #{binding.id}"
  end

  # Moving an LMS identity to a different Dashboard user is allowed: it's the
  # only self-service fix for a student who connected the wrong Wikipedia
  # account. But it also moves grade attribution silently, so leave a trail for
  # support.
  def log_identity_move(context, current_user)
    return if context.user_id.nil? || context.user_id == current_user.id

    Rails.logger.warn(
      "[LTI] relinking LMS identity #{user_lti_id} in binding " \
      "#{context.lti_course_binding_id}: user #{context.user_id} -> #{current_user.id}"
    )
  end

  def raw_idtoken
    @raw_idtoken ||= @client.get('/api/idtoken?raw=true')
  end

  def apply_context_attributes(context, current_user)
    context.user = current_user
    context.lms_id = lms_id
    context.lms_family = lms_family
    context.context_id = legacy_context_id
    context.roles = user_roles
  end

  # The legacy concatenated identifier persisted on the existing
  # `lti_contexts.context_id` column. Retained until the column is dropped
  # in a follow-up PR.
  def legacy_context_id
    "#{lms_context_id}::#{lms_resource_link_id}"
  end
end
