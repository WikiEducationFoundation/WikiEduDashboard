#= Presenter for main page / cohort view
class HomePagePresenter
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
    raise ActionController::RoutingError
      .new('nope') unless Cohort.exists?(slug: cohort_param)
    Cohort.find_by(slug: cohort_param)
  end

  def courses
    cohort.courses.listed.order(:title)
  end
end

#= Pseudo-Cohort that displays all unsubmitted, non-deleted courses
class NullCohort
  def title
    'Unsubmitted Courses'
  end

  def slug
    'none'
  end

  def courses
    Course.unsubmitted_listed
  end

  def students_without_instructor_students
    []
  end

  def trained_count
    0
  end
end
