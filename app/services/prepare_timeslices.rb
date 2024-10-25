# frozen_string_literal: true

# Ensures that the necessary timeslices are created prior to a new update
# of the course statistics.
class PrepareTimeslices
  def initialize(course)
    @course = course
    @timeslice_manager = TimesliceManager.new(@course)
  end

  # Deletes all existing timeslices and recreates them from scratch.
  def recreate_timeslices
    @timeslice_manager.delete_timeslices_for_deleted_course_wikis(@course.wikis.pluck(:wiki_id))
    # Destroy articles courses records to re-create article courses timeslices
    @course.articles_courses.destroy_all
    @timeslice_manager.create_timeslices_for_new_course_wiki_records(@course.wikis)
  end

  # Updates timeslices, making changes based on modifications to course data,
  # such as some wiki/users were added or removed, the start/end course dates changed.
  def adjust_timeslices
    # Ensure initial timeslices are created if this is the first course update
    unless @course.was_course_ever_updated?
      @timeslice_manager.create_timeslices_for_new_course_wiki_records(@course.wikis)
    end
    # Execute update tasks in a specific order
    UpdateTimeslicesCourseUser.new(@course).run
    UpdateTimeslicesCourseWiki.new(@course).run
    UpdateTimeslicesCourseDate.new(@course).run
  end
end
