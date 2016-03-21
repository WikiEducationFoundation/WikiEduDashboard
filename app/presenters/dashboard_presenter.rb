#= Presenter for dashboard
class DashboardPresenter
  include Rails.application.routes.url_helpers

  attr_reader :courses, :current, :past, :submitted, :strictly_current, :current_user

  ORIENTATION_ID = 3

  def initialize(current, past, submitted, strictly_current, current_user)
    @current = current
    @past = past
    @submitted = submitted
    @strictly_current = strictly_current
    @current_user = current_user
  end

  def is_instructor?
    current_user.permissions == User::Permissions::INSTRUCTOR
  end

  def is_admin?
    current_user.permissions == User::Permissions::ADMIN
  end

  # Show the 'Your Courses' label if there are submitted courses
  # OR you're an instructor with existing courses but you still haven't completed orientation
  def show_your_courses_label?
    return true if @submitted.any? && @current.any? # submitted with current courses
    return false if @submitted.any? && @current.empty? && @past.any? # submitted with no current but there are past
    return true if @submitted.any? && @current.empty? && @past.empty? # submitted but no courses
    return true if @current.any? && is_instructor? && !instructor_has_completed_orientation? # current but hasn't completed orientation
  end

  # Show 'Welcome' for people without any courses on the screen, otherwise 'My Dashboard'
  def heading_message
    if @current.any? && @past.any? || @submitted.any?
      return I18n.t("application.my_dashboard")
    else
      return I18n.t("application.greeting2")
    end
  end

  # Show the orientation block if you're an instructor who hasn't completed
  # orientation and you don't have any existing courses
  def show_orientation_block?
    is_instructor? && !instructor_has_completed_orientation? && @current.empty? && @past.empty?
  end

  def can_create_course?
    return true if ENV['open_course_creation']
    return true if is_admin?
    # Instructors who have completed orientation OR have
    # already created a course are allowed to create new courses
    is_instructor? && (instructor_has_completed_orientation? || @current.any? || @past.any?)
  end

  # Show explore button for non instructors/admins
  def show_explore_button?
    current_user.permissions == User::Permissions::NONE
  end

  # Get the url path for orientation
  def orientation_path
    training_module_path('instructors', TrainingModule.find(ORIENTATION_ID).slug)
  end

  # Open mail client
  def opt_out_path
    "mailto:#{ENV['contact_email']}"
  end

  def default_course_type
    ENV['default_course_type'] || 'ClassroomProgramCourse'
  end

  # FIXME: Horrible hack.
  def default_course_string_prefix
    default_course_type.constantize.new.string_prefix
  end

  private

  # Determine if an instructor has completed orientation
  def instructor_has_completed_orientation?
    return true if ENV['disable_onboarding'] == 'true'
    TrainingModulesUsers
      .where(training_module_id: ORIENTATION_ID)
      .where(user_id: current_user.id)
      .where.not(completed_at: nil).any?
  end
end
