# frozen_string_literal: true

# Reconciles a single NRPS member record with the Dashboard's LtiContext
# table. Anonymized posture: NRPS gives us only the opaque LTI user id, roles,
# and status — no names or emails — so members are matched purely by
# user_lti_id. Two states a row can land in:
#
#   1. Already linked (LtiContext.user_id present, from a prior Wikipedia OAuth
#      launch) — refresh roles/status and ensure the CoursesUsers role matches
#      the LMS role.
#   2. Deferred — member is recorded with user_id=nil; it links when the student
#      personally launches from Canvas and completes Wikipedia OAuth. There is
#      no email-based auto-linking (we never receive emails).
#
# Inactive/Deleted members in NRPS are preserved (we don't auto-disenroll
# Dashboard users) but flagged via status. Staff can reconcile manually.
class LtiMemberLinker
  INSTRUCTOR_ROLE_SUFFIXES = LtiSession::INSTRUCTOR_ROLES

  attr_reader :context

  def initialize(binding, member)
    @binding = binding
    @member = member
    perform
  end

  private

  def perform
    @context = find_or_initialize_context
    apply_member_attributes
    @context.linked_at ||= Time.current if @context.user_id.present?
    @context.save!
    enroll_in_course if @context.user_id.present? && @binding.course
  end

  def find_or_initialize_context
    LtiContext.find_or_initialize_by(
      user_lti_id: @member[:user_lti_id],
      lti_course_binding_id: @binding.id
    )
  end

  def apply_member_attributes
    @context.lms_id = @binding.lms_id
    @context.lms_family = @binding.lms_family
    @context.roles = @member[:roles]
  end

  def enroll_in_course
    role = instructor_role? ? CoursesUsers::Roles::INSTRUCTOR_ROLE
                            : CoursesUsers::Roles::STUDENT_ROLE
    return if CoursesUsers.exists?(user_id: @context.user_id,
                                   course_id: @binding.course_id, role:)
    return unless @binding.course.approved?

    JoinCourse.new(course: @binding.course, user: @context.user,
                   role:, real_name: @context.user.real_name)
  end

  def instructor_role?
    Array(@member[:roles]).any? do |str|
      INSTRUCTOR_ROLE_SUFFIXES.any? { |suffix| str.end_with?(suffix) }
    end
  end
end
