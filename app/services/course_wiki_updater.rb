# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/timeslice_manager"
require_dependency "#{Rails.root}/lib/articles_courses_cleaner_timeslice"

class CourseWikiUpdater
  def initialize(course)
    @course = course
    @timeslice_manager = TimesliceManager.new(course)
  end

  def run
    # Get the existing courses wikis
    current_course_wiki_ids = @course.wikis.pluck(:id)
    # Courses wiki for whose exist a course wiki timeslice are considered processed
    processed_courses_wikis = CourseWikiTimeslice.where(course: @course)
                                                 .select(:wiki_id).distinct.pluck(:wiki_id)

    deleted_wiki_ids = processed_courses_wikis - current_course_wiki_ids

    remove_courses_wikis(deleted_wiki_ids)

    new_wiki_ids = current_course_wiki_ids - processed_courses_wikis
    add_courses_wikis(new_wiki_ids)
  end

  private

  def remove_courses_wikis(wiki_ids)
    # Delete timeslices for the deleted wikis
    @timeslice_manager.delete_timeslices_for_deleted_course_wikis wiki_ids
    # Delete articles courses
    ArticlesCoursesCleanerTimeslice.remove_bad_articles_courses(@course, wiki_ids)
  end

  def add_courses_wikis(wiki_ids)
    # Create course wiki timeslice records for new wikis
    @timeslice_manager.create_timeslices_for_new_course_wiki_records wiki_ids
  end
end
