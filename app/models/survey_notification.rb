class SurveyNotification < ActiveRecord::Base
  belongs_to :courses_user
  belongs_to :survey_assignment
  belongs_to :course

  scope :active, -> { where(dismissed: false, completed: false) }
  scope :completed, -> { where(completed: true) }
  scope :dismissed, -> { where(dismissed: true) }

  def send_email
    # In these environments only send emails to the users specified in ENV['survey_test_email']
    return if ['development', 'staging'].include?(Rails.env) && !ENV['survey_test_email'].split(',').include?(user.email)
    return if email_sent_at.present?
    return if user.email.nil?
    SurveyMailer.notification(self).deliver_now
    update_attribute(:email_sent_at, Time.now)
  end

  def send_follow_up
    return unless survey_assignment.follow_up_days_after_first_notification.present?
    return if user.email.nil?
    return unless ready_for_follow_up?
    SurveyMailer.follow_up(self).deliver_now
    update_attributes(last_follow_up_sent_at: Time.now,
                      follow_up_count: follow_up_count + 1)
  end

  def survey_assignment
    SurveyAssignment.find(survey_assignment_id)
  end

  def survey
    survey_assignment.survey
  end

  def user
    CoursesUsers.find(courses_users_id).user
  end

  def course
    Course.find(course_id)
  end

  private

  MAX_FOLLOW_UPS = 3
  def ready_for_follow_up?
    return false if email_sent_at.nil?
    return false if Time.now < last_email_sent_at + time_before_another_email
    return false if follow_up_count >= MAX_FOLLOW_UPS
    true
  end

  def time_before_another_email
    survey_assignment.follow_up_days_after_first_notification.days
  end

  def last_email_sent_at
    last_follow_up_sent_at.present? ? last_follow_up_sent_at : email_sent_at
  end
end
