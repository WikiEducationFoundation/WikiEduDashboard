# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/timeslice_manager"
require_dependency "#{Rails.root}/lib/articles_courses_cleaner_timeslice"

class CourseDateUpdater
  def initialize(course)
    @course = course
    @timeslice_manager = TimesliceManager.new(course)
  end

  def run
    # Get the min course wiki timeslice end date
    min_course_end = CourseWikiTimeslice.where(course: @course)
                                        .minimum(:end)

    # Remove timeslices if there are timesmlices prior to the current start date
    remove_timeslices_prior_to_start_date unless min_course_end > @course.start

    # Get the min course wiki timeslice end start
    min_course_start = CourseWikiTimeslice.where(course: @course)
                                          .minimum(:start)

    add_timeslices_from_new_start_date unless min_course_start <= @course.start
  end

  private

  def remove_timeslices_prior_to_start_date
    mark_new_first_timeslces_as_needs_update

    # Delete course and course user timeslices
    @timeslice_manager.delete_course_wiki_timeslices_prior_to_start_date
    @timeslice_manager.delete_course_user_wiki_timeslices_prior_to_start_date

    # Delete articles courses
    ArticlesCoursesCleanerTimeslice.clean_articles_courses_prior_to_course_start(@course)
  end

  def add_timeslices_from_new_start_date
    mark_new_first_timeslces_as_needs_update

    @timeslice_manager.create_timeslices_for_new_course_start_date
  end

  def mark_new_first_timeslces_as_needs_update
    # If the start date changed, mark the new first timeslices as 'needs_update'
    @course.wikis.each do |wiki|
      timeslice = CourseWikiTimeslice.for_course_and_wiki(@course, wiki)
                                     .for_datetime(@course.start)
                                     .first
      break unless timeslice
      timeslice.update(needs_update: true)
    end
  end
end
