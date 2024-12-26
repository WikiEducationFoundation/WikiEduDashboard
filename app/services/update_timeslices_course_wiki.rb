# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/timeslice_manager"
require_dependency "#{Rails.root}/lib/articles_courses_cleaner_timeslice"

class UpdateTimeslicesCourseWiki
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

    # Check if some wiki changes timeslice duration
    update_timeslices_durations
  end

  private

  def remove_courses_wikis(wiki_ids)
    # Delete timeslices for the deleted wikis
    @timeslice_manager.delete_timeslices_for_deleted_course_wikis wiki_ids
    # Delete articles courses
    ArticlesCoursesCleanerTimeslice.clean_articles_courses_for_wiki_ids(@course, wiki_ids)
  end

  def add_courses_wikis(wiki_ids)
    # Create course wiki timeslice records for new wikis
    @timeslice_manager.create_timeslices_for_new_course_wiki_records wiki_ids
  end

  def update_timeslices_durations
    @course.wikis.each do |wiki|
      start = @timeslice_manager.get_ingestion_start_time_for_wiki wiki
      timeslice = @course.course_wiki_timeslices.where(wiki:, start:).first
      effective_timeslice_duration = timeslice.end - timeslice.start
      real_timeslice_duration = @course.timeslice_duration
      # Continue if timeslice duration didn't change for the wiki
      next unless effective_timeslice_duration != real_timeslice_duration
      @timeslice_manager.delete_course_wiki_timeslices_after_date([wiki], start - 1.second)
      @timeslice_manager.create_wiki_timeslices_up_to_new_course_end_date(wiki)
    end
  end
end
