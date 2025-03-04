# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/timeslice_manager"
require_dependency "#{Rails.root}/lib/timeslice_cleaner"
require_dependency "#{Rails.root}/lib/articles_courses_cleaner_timeslice"

class UpdateTimeslicesCourseDate
  def initialize(course)
    @course = course
    @timeslice_manager = TimesliceManager.new(course)
    @timeslice_cleaner = TimesliceCleaner.new(course)
  end

  def run
    update_timeslices_if_drastic_change
    update_timeslices_if_start_date_changed
    update_timeslices_if_end_date_changed
  end

  private

  # A 'drastic' change occurs when the previous course period and the current one have no overlap.
  # In this case, we delete the existing timeslices and generate new ones.
  def update_timeslices_if_drastic_change
    min_course_start = CourseWikiTimeslice.where(course: @course).minimum(:start)
    max_course_end = CourseWikiTimeslice.where(course: @course).maximum(:end)

    drastic_change = @course.start >= max_course_end || @course.end <= min_course_start

    return unless drastic_change

    Rails.logger.info "UpdateTimeslicesCourseDate: Course: #{@course.slug}\
    Drastic date change. Recreating timeslices."

    remove_timeslices_prior_to_start_date
    remove_timeslices_after_end_date
    @timeslice_manager.create_timeslices_for_new_course_wiki_records(@course.wikis,
                                                                     needs_update: true)
  end

  def update_timeslices_if_start_date_changed
    # Get the min course wiki timeslice end date
    min_course_end = CourseWikiTimeslice.where(course: @course)
                                        .minimum(:end)

    # Remove timeslices if there are timeslices prior to the current start date
    remove_timeslices_prior_to_start_date unless min_course_end > @course.start

    # Each wiki may use a different timeslice duration, so this has to be done per wiki
    @course.wikis.each do |wiki|
      min_course_start = CourseWikiTimeslice.for_course_and_wiki(@course, wiki).minimum(:start)
      add_wiki_timeslices_from_new_start_date(wiki) unless min_course_start <= @course.start
    end
  end

  def update_timeslices_if_end_date_changed
    # Get the max course wiki timeslice start date
    max_course_start = CourseWikiTimeslice.where(course: @course)
                                          .maximum(:start)

    # Remove timeslices if there are timeslices after the current end date
    remove_timeslices_after_end_date unless max_course_start <= @course.end

    # Each wiki may use a different timeslice duration, so this has to be done per wiki
    @course.wikis.each do |wiki|
      max_course_end = CourseWikiTimeslice.for_course_and_wiki(@course, wiki).maximum(:end)
      add_wiki_timeslices_up_to_new_end_date(wiki) unless max_course_end >= @course.end
    end
  end

  def add_wiki_timeslices_up_to_new_end_date(wiki)
    mark_old_last_wiki_timeslce_as_needs_update(wiki)

    Rails.logger.info "UpdateTimeslicesCourseDate: Course: #{@course.slug}\
    Adding data up to: #{@course.end}"

    @timeslice_manager.create_wiki_timeslices_up_to_new_course_end_date(wiki)
  end

  def remove_timeslices_prior_to_start_date
    mark_new_first_timeslce_as_needs_update

    Rails.logger.info "UpdateTimeslicesCourseDate: Course: #{@course.slug}\
    Removing data prior to: #{@course.start}"

    # Delete course and course user timeslices
    @timeslice_cleaner.delete_course_wiki_timeslices_prior_to_start_date
    @timeslice_cleaner.delete_course_user_wiki_timeslices_prior_to_start_date

    # Delete articles courses
    ArticlesCoursesCleanerTimeslice.clean_articles_courses_prior_to_course_start(@course)
  end

  def remove_timeslices_after_end_date
    mark_old_last_timeslce_as_needs_update

    Rails.logger.info "UpdateTimeslicesCourseDate: Course: #{@course.slug}\
    Removing data after to: #{@course.end}"

    # Delete course and course user timeslices
    @timeslice_cleaner.delete_course_wiki_timeslices_after_end_date
    @timeslice_cleaner.delete_course_user_wiki_timeslices_after_end_date

    # Delete articles courses
    ArticlesCoursesCleanerTimeslice.clean_articles_courses_after_course_end(@course)
  end

  def add_wiki_timeslices_from_new_start_date(wiki)
    mark_new_wiki_first_timeslce_as_needs_update(wiki)

    Rails.logger.info "UpdateTimeslicesCourseDate: Course: #{@course.slug}\
    Adding data after to: #{@course.start}"

    @timeslice_manager.create_wiki_timeslices_for_new_course_start_date(wiki)
  end

  def mark_new_first_timeslce_as_needs_update
    # If the start date changed, mark the new first timeslices as 'needs_update'
    @course.wikis.each do |wiki|
      mark_new_wiki_first_timeslce_as_needs_update(wiki)
    end
  end

  def mark_new_wiki_first_timeslce_as_needs_update(wiki)
    # If the start date changed, mark the new first timeslices as 'needs_update'
    timeslice = CourseWikiTimeslice.for_course_and_wiki(@course, wiki)
                                   .for_datetime(@course.start)
                                   .first
    return unless timeslice
    timeslice.update(needs_update: true)
  end

  def mark_old_last_timeslce_as_needs_update
    # If the end date changed, mark the previous last timeslices as 'needs_update'
    @course.wikis.each do |wiki|
      mark_old_last_wiki_timeslce_as_needs_update(wiki)
    end
  end

  def mark_old_last_wiki_timeslce_as_needs_update(wiki)
    # If the end date changed, mark the previous last timeslices as 'needs_update'
    timeslice = CourseWikiTimeslice.for_course_and_wiki(@course, wiki)
                                   .last
    return unless timeslice
    timeslice.update(needs_update: true)
  end
end
