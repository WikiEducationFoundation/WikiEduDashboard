# frozen_string_literal: true

# Reconciles a single NRPS member record with the Dashboard's LtiContext
# table. Three states a row can land in:
#
#   1. Already linked (LtiContext.user_id present) — refresh email/name/
#      roles/status, ensure CoursesUsers role matches the LMS role.
#   2. Auto-linkable (member.email matches an existing User.email,
#      case-insensitive) — populate LtiContext.user_id and enroll via
#      JoinCourse.
#   3. Deferred — member is recorded with user_id=nil; will be linked when
#      they personally launch from Canvas and complete Wikipedia OAuth.
#
# Inactive/Deleted members in NRPS are preserved (we don't auto-disenroll
# Dashboard users) but flagged via status. Staff can reconcile manually.
class LtiMemberLinker
  INSTRUCTOR_ROLE_SUFFIXES = LtiSession::INSTRUCTOR_ROLES

  attr_reader :context, :outcome

  def initialize(binding, member)
    @binding = binding
    @member = member
    @outcome = :pending
    perform
  end

  def linked?
    @outcome == :linked || @outcome == :already_linked
  end

  private

  def perform
    @context = find_or_initialize_context
    apply_member_attributes
    auto_link_by_email if @context.user_id.nil?
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
    @context.email = @member[:email]
    @context.name = @member[:name]
    @context.roles = @member[:roles]
  end

  def auto_link_by_email
    email = @member[:email].to_s.strip
    return if email.blank?

    user = User.where('lower(email) = ?', email.downcase).first
    return unless user

    @context.user = user
    @outcome = :linked
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
