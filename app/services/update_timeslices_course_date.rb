# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/timeslice_manager"
require_dependency "#{Rails.root}/lib/articles_courses_cleaner_timeslice"

class UpdateTimeslicesCourseDate
  def initialize(course)
    @course = course
    @timeslice_manager = TimesliceManager.new(course)
  end

  def run
    update_timeslices_if_start_date_changed
    update_timeslices_if_end_date_changed
  end

  private

  def update_timeslices_if_start_date_changed
    # Get the min course wiki timeslice end date
    min_course_end = CourseWikiTimeslice.where(course: @course)
                                        .minimum(:end)

    # Remove timeslices if there are timeslices prior to the current start date
    remove_timeslices_prior_to_start_date unless min_course_end > @course.start

    # There is no guarantee that all wikis are in the same state.
    # If at least one wiki is missing timeslices, then we need to add new timeslices.
    max_min_course_start = CourseWikiTimeslice.max_min_course_start(@course)

    add_timeslices_from_new_start_date unless max_min_course_start <= @course.start
  end

  def update_timeslices_if_end_date_changed
    # Get the max course wiki timeslice start date
    max_course_start = CourseWikiTimeslice.where(course: @course)
                                          .maximum(:start)

    # Remove timeslices if there are timeslices after the current end date
    remove_timeslices_after_end_date unless max_course_start <= @course.end

    # There is no guarantee that all wikis are in the same state.
    # If at least one wiki is missing timeslices, then we need to add new timeslices.
    min_max_course_end = CourseWikiTimeslice.min_max_course_end(@course)

    add_timeslices_up_to_new_end_date unless min_max_course_end >= @course.end
  end

  def add_timeslices_up_to_new_end_date
    mark_old_last_timeslce_as_needs_update

    @timeslice_manager.create_timeslices_up_to_new_course_end_date
  end

  def remove_timeslices_prior_to_start_date
    mark_new_first_timeslce_as_needs_update

    # Delete course and course user timeslices
    @timeslice_manager.delete_course_wiki_timeslices_prior_to_start_date
    @timeslice_manager.delete_course_user_wiki_timeslices_prior_to_start_date

    # Delete articles courses
    ArticlesCoursesCleanerTimeslice.clean_articles_courses_prior_to_course_start(@course)
  end

  def remove_timeslices_after_end_date
    mark_old_last_timeslce_as_needs_update

    # Delete course and course user timeslices
    @timeslice_manager.delete_course_wiki_timeslices_after_end_date
    @timeslice_manager.delete_course_user_wiki_timeslices_after_end_date

    # Delete articles courses
    ArticlesCoursesCleanerTimeslice.clean_articles_courses_after_course_end(@course)
  end

  def add_timeslices_from_new_start_date
    mark_new_first_timeslce_as_needs_update

    @timeslice_manager.create_timeslices_for_new_course_start_date
  end

  def mark_new_first_timeslce_as_needs_update
    # If the start date changed, mark the new first timeslices as 'needs_update'
    @course.wikis.each do |wiki|
      timeslice = CourseWikiTimeslice.for_course_and_wiki(@course, wiki)
                                     .for_datetime(@course.start)
                                     .first
      break unless timeslice
      timeslice.update(needs_update: true)
    end
  end

  def mark_old_last_timeslce_as_needs_update
    # If the end date changed, mark the previous last timeslices as 'needs_update'
    @course.wikis.each do |wiki|
      timeslice = CourseWikiTimeslice.for_course_and_wiki(@course, wiki)
                                     .last
      break unless timeslice
      timeslice.update(needs_update: true)
    end
  end
end
