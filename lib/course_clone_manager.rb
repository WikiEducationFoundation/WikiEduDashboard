class CourseCloneManager

  def initialize(course, user)
    @course = course
    @user = user
  end

  def clone!
    @clone = @course.deep_clone include: [ { weeks:  { blocks: :gradeable } } ]
    sanitize_clone_info
    update_title_and_slug
    clear_dates
    set_instructor
    return @clone
  end

  private

  def sanitize_clone_info
    @clone.title = "#{@course.title} (Copy)"
    set_slug(@clone)
    @clone.passcode = Course.generate_passcode
    @clone.submitted = false
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
    @clone.blocks.update_all(due_date: nil)
  end

  def set_instructor
    CoursesUsers.create!(course_id: @clone.id, user_id: @user.id, role: 1)
  end

  def set_slug(course)
    course.slug = "#{course.school}/#{course.title}_(#{course.term})".gsub(' ', '_')
  end
end
