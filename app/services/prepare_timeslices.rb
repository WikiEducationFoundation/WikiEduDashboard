# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/data_cycle/update_debugger"
# Ensures that the necessary timeslices are created prior to a new update
# of the course statistics.
class PrepareTimeslices
  def initialize(course, debugger, update_service: nil)
    @course = course
    @timeslice_manager = TimesliceManager.new(@course)
    @timeslice_cleaner = TimesliceCleaner.new(@course)
    @debugger = debugger
    @update_service = update_service
  end

  # Deletes all existing timeslices and recreates them from scratch.
  def recreate_timeslices
    @timeslice_cleaner.delete_timeslices_for_deleted_course_wikis(@course.wikis.pluck(:wiki_id))
    # Destroy articles courses records to re-create article courses timeslices, except for
    # untracked articles courses so that we don't miss they're untracked.
    @course.articles_courses.tracked.destroy_all
    @timeslice_manager.create_timeslices_for_new_course_wiki_records(@course.wikis)
    @debugger.log_update_progress :timeslices_recreated
  end

  # Updates timeslices, making changes based on modifications to course data,
  # such as some wiki/users were added or removed, the start/end course dates changed.
  def adjust_timeslices
    # Ensure initial timeslices are created if this is the first course update
    unless @course.was_course_ever_updated?
      @timeslice_manager.create_timeslices_for_new_course_wiki_records(@course.wikis)
      return
    end
    # Execute update tasks in a specific order
    UpdateTimeslicesCourseWiki.new(@course).run
    UpdateTimeslicesCourseUser.new(@course, update_service: @update_service).run
    UpdateTimeslicesUntrackedArticle.new(@course).run
    UpdateTimeslicesCourseDate.new(@course).run
    UpdateTimeslicesScopedArticle.new(@course).run
    @debugger.log_update_progress :timeslices_adjusted
  end
end
