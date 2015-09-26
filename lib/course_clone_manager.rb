#= Procedures for creating a duplicate of an existing course for reuse
class CourseCloneManager
  def initialize(course, user)
    @course = course
    @user = user
  end

  def clone!
    @clone = @course.deep_clone include: [{ weeks:  { blocks: :gradeable } }]
    sanitize_clone_info
    update_title_and_slug
    clear_dates
    set_instructor
    return @clone
  end

  private

  def sanitize_clone_info
    @clone.term = "CLONED FROM #{@course.term}"
    @clone.cloned_status = 1
    @clone.slug = course_slug(@clone)
    @clone.passcode = Course.generate_passcode
    @clone.submitted = false

    # The datepickers require an ititial date, so we set these to today's date
    today = Date.today
    @clone.start = today
    @clone.end = today
    @clone.timeline_start = today
    @clone.timeline_end = today

    @clone.save
    @clone.update_cache
  end

  def update_title_and_slug
    new_course = Course.last
    new_course.update_attributes(
      title: @clone.title,
      slug: @clone.slug
    )
  end

  def clear_dates
    @clone.update_attributes(meeting_days: nil,
                             day_exceptions: nil,
                             weekdays: '0000000',
                             no_day_exceptions: nil)
    @clone.blocks.update_all(due_date: nil)
    @clone.reload
  end

  def set_instructor
    CoursesUsers.create!(course_id: @clone.id, user_id: @user.id, role: 1)
  end

  def course_slug(course)
    "#{course.school}/#{course.title}_(#{course.term})".gsub(' ', '_')
  end
end
