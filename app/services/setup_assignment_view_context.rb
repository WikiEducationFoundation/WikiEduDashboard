# frozen_string_literal: true

# Bundles the data for the in-Canvas assignment view of the "Wikipedia
# account" (WikipediaSetup) gradebook column: which of the Canvas course's
# students have connected a Wikipedia account.
#
# Not-yet-connected members are counted, not listed. Under the anonymized
# posture the only label we hold for them is the opaque LMS user id, which
# identifies nobody — and no Canvas page an instructor can reach resolves it
# (`lti_user_id:` works on the API and the account-admin user page, but the
# course roster page rejects it). The legible list of the same students is
# the Canvas gradebook column itself, where they appear by Canvas's own names
# with no score, so the view points there instead of printing opaque ids.
class SetupAssignmentViewContext
  include LtiRosterFocus

  Row = Struct.new(:name, :username, :removed_in_lms, keyword_init: true)

  attr_reader :line_item, :user

  def initialize(line_item:, instructor:, user: nil, focus_user: nil)
    @line_item = line_item
    @instructor = instructor
    @user = user
    @focus_user = focus_user
    @binding = line_item.lti_course_binding
  end

  # The launching student's own drill-down into the Dashboard: the
  # per-student details view on the bound course.
  def student_details_path
    course = @binding.course
    return if @user.nil? || course.nil?

    "/courses/#{course.slug}/students/articles/#{@user.url_encoded_username}"
  end

  def instructor?
    @instructor
  end

  def course
    @binding.course
  end

  def title
    @line_item.label
  end

  # One row per connected student. Identity comes from the Dashboard side,
  # mirroring the course's Students tab (designed around anonymized mode,
  # where the LMS shares no names): `name` is the real name on the student's
  # CoursesUsers enrollment — blank if they didn't give one — and `username`
  # their Wikipedia account. `removed_in_lms` flags one whose stored NRPS
  # status says Canvas has since removed or suspended them — reconciliation
  # info for the instructor; nothing is disenrolled automatically.
  def rows
    @rows ||= connected_contexts.map do |context|
      Row.new(name: enrollment_real_names[context.user_id],
              username: context.user&.username,
              removed_in_lms: context.removed_from_lms?)
    end
  end

  def connected_count
    connected_contexts.size
  end

  # Student memberships still awaiting a Wikipedia OAuth link — the roster's
  # actionable state, carried as a count because they have no legible label.
  def pending_count
    total_count - connected_count
  end

  # Every student membership, connected or not. Zero means the roster sync
  # hasn't run (or found nobody) yet, which the view reports differently from
  # "nobody has connected".
  def total_count
    student_contexts.size
  end

  private

  # Learners by LMS role, so the connected/not-connected counts don't include
  # staff or a Canvas observer (who is neither).
  def student_contexts
    @student_contexts ||= focused(@binding.lti_contexts.select(&:learner?))
  end

  def connected_contexts
    @connected_contexts ||= student_contexts.select(&:linked?).sort_by { |c| sort_key(c) }
  end

  def sort_key(context)
    (enrollment_real_names[context.user_id] || context.user&.username || '').downcase
  end

  # One query for the whole roster, not one per row.
  def enrollment_real_names
    @enrollment_real_names ||=
      CoursesUsers.where(course_id: @binding.course_id)
                  .pluck(:user_id, :real_name).to_h
  end
end
