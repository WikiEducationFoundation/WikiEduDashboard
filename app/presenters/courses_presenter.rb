# frozen_string_literal: true
require "#{Rails.root}/lib/word_count"

#= Presenter for courses / cohort view
class CoursesPresenter
  attr_reader :current_user, :cohort_param

  def initialize(current_user, cohort_param)
    @current_user = current_user
    @cohort_param = cohort_param
  end

  def user_courses
    return unless current_user
    current_user.courses.current_and_future
  end

  def cohort
    return NullCohort.new if cohort_param == 'none'
    @cohort ||= Cohort.find_by(slug: cohort_param)
    raise NoCohortError if @cohort.nil? && cohort_param == ENV['default_cohort']
    @cohort
  end

  def courses
    cohort.courses
  end

  def courses_by_recent_edits
    # Sort first by recent edit count, and then by course title
    courses.sort_by { |course| [-course.recent_edit_count, course.title] }
  end

  def word_count
    WordCount.from_characters courses.sum(:character_sum)
  end

  def default_course_type
    ENV['default_course_type'] || 'ClassroomProgramCourse'
  end

  def course_string_prefix
    if default_course_type == 'ClassroomProgramCourse'
      'courses'
    else
      'courses_generic'
    end
  end

  def uploads_in_use_count
    @uploads_in_use_count ||= courses.sum(:uploads_in_use_count)
    @uploads_in_use_count
  end

  def upload_usage_count
    @upload_usage_count ||= courses.sum(:upload_usages_count)
    @upload_usage_count
  end

  class NoCohortError < StandardError; end
end

#= Pseudo-Cohort that displays all unsubmitted, non-deleted courses
class NullCohort
  def title
    I18n.t('courses.unsubmitted')
  end

  def slug
    'none'
  end

  def courses
    Course.unsubmitted.order(created_at: :desc)
  end

  def students_without_nonstudents
    []
  end

  def trained_percent
    0
  end
end
