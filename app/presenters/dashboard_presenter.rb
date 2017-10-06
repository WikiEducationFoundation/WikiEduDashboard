# frozen_string_literal: true

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

  def is_campaign_organizer?
    campaigns.any?
  end

  def campaigns
    current_user.campaigns
  end

  # Show the 'Your Courses' label if there are current, submitted courses
  # OR you're an instructor with existing courses but you still haven't completed orientation
  def show_your_courses_label?
    return true if submitted_and_current_courses?
    return false if only_past_submitted_courses?
    return true if submitted_but_no_current_or_past_courses?
    return true if current_courses_but_incomplete_instructor_training?
  end

  # Show 'Welcome' for people without any courses on the screen, otherwise 'My Dashboard'
  def heading_message
    return I18n.t('application.my_dashboard') if @current.any? && @past.any? || @submitted.any?
    return I18n.t('application.greeting2')
  end

  # Show the orientation block if you're an instructor who hasn't completed
  # orientation and you don't have any existing courses
  def show_orientation_block?
    is_instructor? && !instructor_has_completed_orientation? && @current.empty? && @past.empty?
  end

  def show_orientation_review?
    return false if Features.disable_onboarding?
    is_instructor? && instructor_has_completed_orientation?
  end

  def can_create_course?
    return true if Features.open_course_creation?
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
    Features.default_course_type
  end

  def default_use_start_and_end_times
    default_course_type.constantize.new.use_start_and_end_times
  end

  def course_string_prefix
    Features.default_course_string_prefix
  end

  private

  # Determine if an instructor has completed orientation
  def instructor_has_completed_orientation?
    return true if Features.disable_onboarding?
    TrainingModulesUsers
      .where(training_module_id: ORIENTATION_ID)
      .where(user_id: current_user.id)
      .where.not(completed_at: nil).any?
  end

  def submitted_and_current_courses?
    @submitted.any? && @current.any?
  end

  def only_past_submitted_courses?
    @submitted.any? && @current.empty? && @past.any?
  end

  def submitted_but_no_current_or_past_courses?
    @submitted.any? && @current.empty? && @past.empty?
  end

  def current_courses_but_incomplete_instructor_training?
    @current.any? && is_instructor? && !instructor_has_completed_orientation?
  end
end
