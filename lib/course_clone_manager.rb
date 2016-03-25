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
    tag_course
    return @clone
  end

  private

  def sanitize_clone_info
    @clone.term = "CLONED FROM #{@course.term}"
    @clone.cloned_status = 1
    @clone.slug = course_slug(@clone)
    @clone.passcode = Course.generate_passcode
    @clone.submitted = false
    # If a legacy course is cloned, switch the type to ClassroomProgramCourse.
    @clone.type = 'ClassroomProgramCourse' if @clone.legacy?

    # The datepickers require an ititial date, so we set these to today's date
    today = Time.zone.today
    @clone.start = today
    @clone.end = today
    @clone.timeline_start = today
    @clone.timeline_end = today

    @clone.save
    @clone = Course.find(@clone.id) # Re-load the course to ensure correct course type
    @clone.update_cache
  end

  def update_title_and_slug
    @clone.update_attributes(
      title: @clone.title,
      slug: @clone.slug
    )
  end

  def clear_dates
    @clone.update_attributes(day_exceptions: '',
                             weekdays: '0000000',
                             no_day_exceptions: false)
    @clone.blocks.update_all(due_date: nil)
    @clone.reload
  end

  def set_instructor
    CoursesUsers.create!(course_id: @clone.id, user_id: @user.id, role: 1)
  end

  def tag_course
    tag_manager = TagManager.new(@clone)
    tag_manager.initial_tags(creator: @user)
    tag_manager.add(tag: 'cloned')
  end

  def course_slug(course)
    "#{course.school}/#{course.title}_(#{course.term})".tr(' ', '_')
  end
end
