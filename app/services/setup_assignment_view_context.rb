# frozen_string_literal: true

# Bundles the data for the in-Canvas assignment view of the "Wikipedia
# account" (WikipediaSetup) gradebook column: which of the Canvas course's
# students have connected a Wikipedia account. Unlike the Block-backed
# views, not-yet-linked memberships matter here — they are exactly the rows
# the instructor opens this column to find, so they're listed (first) even
# though all we can show for them is the LMS-supplied name or an opaque id.
class SetupAssignmentViewContext
  Row = Struct.new(:name, :username, :connected, keyword_init: true) do
    def connected?
      connected
    end
  end

  attr_reader :line_item, :user

  def initialize(line_item:, instructor:, user: nil)
    @line_item = line_item
    @instructor = instructor
    @user = user
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

  # Identity comes from the Dashboard side, mirroring the course's Students
  # tab (designed around anonymized mode, where the LMS shares no names):
  # `name` is the real name on the student's CoursesUsers enrollment and
  # `username` their Wikipedia account — both blank until they connect.
  def rows
    @rows ||= student_contexts.map do |context|
      Row.new(name: display_name(context), username: context.user&.username,
              connected: context.linked?)
    end
  end

  def connected_count
    rows.count(&:connected?)
  end

  def total_count
    rows.size
  end

  private

  # Every student membership (linked or not), not-yet-connected first —
  # those are the actionable rows — then by name.
  def student_contexts
    @binding.lti_contexts.reject(&:instructor?)
            .sort_by { |context| [context.linked? ? 1 : 0, sort_key(context)] }
  end

  def sort_key(context)
    (display_name(context) || context.user&.username || '').downcase
  end

  # Connected rows show the Dashboard-side real name (the CoursesUsers
  # enrollment record, same source as the Students tab) — may be blank if
  # the student didn't provide one. Pending rows have no Dashboard identity;
  # under anonymized mode all the LMS shares is the opaque LTI user id, so
  # that's their label (legibility follow-up tracked in the todos).
  def display_name(context)
    return context.name.presence || context.user_lti_id unless context.linked?

    enrollment_real_names[context.user_id]
  end

  # One query for the whole roster, not one per row.
  def enrollment_real_names
    @enrollment_real_names ||=
      CoursesUsers.where(course_id: @binding.course_id)
                  .pluck(:user_id, :real_name).to_h
  end
end
