require "#{Rails.root}/lib/word_count"

#= Presenter for courses / cohort view
class CoursesPresenter
  attr_reader :current_user, :cohort_param

  def initialize(current_user, cohort_param)
    @current_user = current_user
    @cohort_param = cohort_param
  end

  def admin_courses
    return unless current_user && current_user.admin?
    Course.submitted_listed
  end

  def user_courses
    return unless current_user
    current_user.courses.current_and_future.listed
  end

  def cohort
    return NullCohort.new if cohort_param == 'none'
    return unless Cohort.exists?(slug: cohort_param)
    Cohort.find_by(slug: cohort_param)
  end

  def courses
    cohort.courses.listed
  end

  def courses_by_recent_edits
    courses.sort_by(&:recent_edit_count).reverse
  end

  def word_count
    WordCount.from_characters courses.sum(:character_sum)
  end
end

#= Pseudo-Cohort that displays all unsubmitted, non-deleted courses
class NullCohort
  def title
    I18n.t("courses.unsubmitted")
  end

  def slug
    'none'
  end

  def courses
    Course.unsubmitted_listed.order(created_at: :desc)
  end

  def students_without_nonstudents
    []
  end

  def trained_percent
    0
  end
end
