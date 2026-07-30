# frozen_string_literal: true

# Reconciles a single NRPS member record with the Dashboard's LtiContext
# table. Anonymized posture: NRPS gives us only the opaque LTI user id, roles,
# and status — no names or emails — so members are matched purely by
# user_lti_id. Two states a row can land in:
#
#   1. Already linked (LtiContext.user_id present, from a prior Wikipedia OAuth
#      launch) — refresh the LMS roles, and promote the Dashboard enrollment if
#      the LMS now calls this member course staff.
#   2. Deferred — member is recorded with user_id=nil; it links when the student
#      personally launches from Canvas and completes Wikipedia OAuth. There is
#      no email-based auto-linking (we never receive emails).
#
# Two deliberate non-goals. Both are policy calls an operator should make, not
# defaults to fall into:
#
#   - **No auto-disenrollment.** An Inactive or Deleted NRPS member keeps
#     whatever Dashboard enrollment they already have — dropping it would take
#     their assignment and article records with it. The status is persisted
#     (`lms_membership_status`, refreshed for every member on every sync) so
#     staff can see a "was removed in Canvas" member to reconcile, but here it
#     only stops us *newly* enrolling someone Canvas has already removed.
#   - **No auto-demotion.** A member the LMS no longer calls staff keeps their
#     Dashboard role — reaffirmed as policy 2026-07-30. Dashboard instructor
#     roles carry no provenance (nothing records whether this linker or an
#     ordinary Dashboard flow granted one), and the Dashboard course exists
#     independently of Canvas — its creator may not be on the Canvas roster at
#     all — so demoting on NRPS could strip the course owner's own access.
#     Consequence, accepted: a former Canvas instructor keeps Dashboard edit
#     rights until revoked manually. (An earlier version of this comment argued
#     from Canvas TAs not mapping to instructor here; that was wrong — Canvas
#     sends the base Instructor role for TAEnrollments, so TAs do map.)
class LtiMemberLinker
  INSTRUCTOR_ROLE_SUFFIXES = LtiSession::INSTRUCTOR_ROLES

  # "Don't newly enroll this member" — see the definition on the model, where
  # the persisted status is also read back for the staff-facing roster flag.
  REMOVED_STATUSES = LtiContext::REMOVED_STATUSES

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
    @context.lms_membership_status = @member[:status]
  end

  # Both guards come before any path that changes an enrollment. They used to sit
  # after the promotion branch, which meant a member Canvas had deleted from the
  # course could still be promoted to Dashboard instructor on the strength of
  # their stale staff roles, and promotion skipped the approval check that the
  # JoinCourse path applies.
  def enroll_in_course
    role = target_role
    return if role.nil? || removed_from_lms?
    return unless @binding.course.approved?
    return if CoursesUsers.exists?(user_id: @context.user_id,
                                   course_id: @binding.course_id, role:)

    conflicting = conflicting_enrollment
    return promote(conflicting, role) if conflicting

    JoinCourse.new(course: @binding.course, user: @context.user,
                   role:, real_name: @context.user.real_name)
  end

  # nil for a membership that is neither staff nor learner — a Canvas observer
  # or designer, or a role we don't recognize. Those are recorded in
  # lti_contexts so the roster reflects Canvas, but never enrolled. Before the
  # learner allowlist existed this fell through to STUDENT_ROLE, and because
  # `Mentor` was also treated as staff, a Canvas observer was enrolled as a
  # Dashboard *instructor*.
  def target_role
    return CoursesUsers::Roles::INSTRUCTOR_ROLE if instructor_role?
    return CoursesUsers::Roles::STUDENT_ROLE if learner_role?

    nil
  end

  # An enrollment in some *other* role. On a Wiki Ed course that is exactly why
  # JoinCourse refuses (one role per user per course), so a role change has to be
  # applied in place — routing through JoinCourse would silently no-op with
  # 'cannot_join_twice' and the LMS role change would never land. A course that
  # allows multiple roles has no conflict: JoinCourse just adds the new role.
  def conflicting_enrollment
    return nil if @binding.course.multiple_roles_allowed?

    CoursesUsers.find_by(user_id: @context.user_id, course_id: @binding.course_id)
  end

  # Promotion only, never demotion — see the class comment.
  def promote(courses_user, role)
    return unless role == CoursesUsers::Roles::INSTRUCTOR_ROLE

    courses_user.update!(role:)
  end

  def removed_from_lms?
    REMOVED_STATUSES.include?(@member[:status].to_s)
  end

  def instructor_role?
    LtiSession.role_match?(@member[:roles], INSTRUCTOR_ROLE_SUFFIXES)
  end

  def learner_role?
    LtiSession.role_match?(@member[:roles], LtiSession::LEARNER_ROLES)
  end
end
