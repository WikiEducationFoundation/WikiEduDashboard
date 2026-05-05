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

  def nrps_url
    @idtoken.dig('services', 'namesAndRoles', 'contextMembershipsUrl')
  end

  def ags_lineitems_url
    @idtoken.dig('services', 'assignmentAndGrades', 'lineItemsUrl') ||
      @idtoken.dig('services', 'assignmentAndGrades', 'lineitemsUrl')
  end

  # Looks up or creates the LtiCourseBinding for this launch. The binding's
  # `course_id` is left nil; the controller's setup flow populates it once
  # the instructor links to or creates a Dashboard course.
  def find_or_create_binding!
    LtiCourseBinding.find_or_create_by!(
      lms_id:,
      lms_context_id:,
      lms_resource_link_id:
    ) do |binding|
      binding.lms_family = lms_family
      binding.nrps_url = nrps_url
      binding.ags_lineitems_url = ags_lineitems_url
    end
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
