# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/timeslice_manager"
require_dependency "#{Rails.root}/lib/timeslice_cleaner"
require_dependency "#{Rails.root}/lib/articles_courses_cleaner_timeslice"

class UpdateTimeslicesCourseWiki
  def initialize(course)
    @course = course
    @timeslice_manager = TimesliceManager.new(course)
    @timeslice_cleaner = TimesliceCleaner.new(course)
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
    return if wiki_ids.empty?
    Rails.logger.info { "UpdateTimeslicesCourseWiki: Deleting wikis: #{wiki_ids}" }
    # Delete timeslices for the deleted wikis
    @timeslice_cleaner.delete_timeslices_for_deleted_course_wikis wiki_ids
    # Delete articles courses
    ArticlesCoursesCleanerTimeslice.clean_articles_courses_for_wiki_ids(@course, wiki_ids)
  end

  def add_courses_wikis(wiki_ids)
    return if wiki_ids.empty?
    wikis = Wiki.where(id: wiki_ids)
    Rails.logger.info { "UpdateTimeslicesCourseWiki: Adding wikis: #{wiki_ids}" }
    # Create course wiki timeslice records for new wikis
    @timeslice_manager.create_timeslices_for_new_course_wiki_records(wikis)
  end

  def update_timeslices_durations
    recreate_unprocessed_timeslices
    recreate_timeslices_needing_update
  end

  def recreate_unprocessed_timeslices
    @course.wikis.each do |wiki|
      start = @timeslice_manager.get_ingestion_start_time_for_wiki wiki
      timeslice = @course.course_wiki_timeslices.where(wiki:, start:).first
      next unless timeslice && needs_recreate?(timeslice,
                                               @timeslice_manager.timeslice_duration(wiki))

      @timeslice_cleaner.delete_course_wiki_timeslices_after_date([wiki], start - 1.second)
      @timeslice_cleaner.delete_course_user_wiki_timeslices_after_date([wiki], start - 1.second)
      @timeslice_cleaner.delete_article_course_timeslices_after_date([wiki], start - 1.second)
      @timeslice_manager.create_wiki_timeslices_up_to_new_course_end_date(wiki)
    end
  end

  def recreate_timeslices_needing_update
    @course.wikis.each do |wiki|
      CourseWikiTimeslice.for_course_and_wiki(@course, wiki).needs_update.find_each do |timeslice|
        next unless needs_recreate?(timeslice,
                                    @timeslice_manager.timeslice_duration(wiki),
                                    needs_update: true)

        @timeslice_cleaner.delete_timeslices_for_period([wiki], timeslice.start, timeslice.end)
        @timeslice_manager.create_wiki_timeslices_for_period(wiki, timeslice.start,
                                                             timeslice.end - 1.second)
      end
    end
  end

  # Determines whether a timeslice should be recreated.
  # The criteria is:
  # - For current or future timeslices: recreate if the new duration differs
  #   from the effective duration.
  # - For timeslices marked as needs_update:
  #   recreate only if the new duration differs and evenly divides the effective duration.
  def needs_recreate?(timeslice, new_duration, needs_update: false)
    effective_duration = timeslice.end - timeslice.start
    # No need to recreate if duration didn't change
    return false if effective_duration == new_duration
    return true unless needs_update
    # Recreate only if the new duration evenly divides the effective duration
    (effective_duration % new_duration).zero?
  end
end
