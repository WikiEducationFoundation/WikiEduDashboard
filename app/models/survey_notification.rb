class SurveyNotification < ActiveRecord::Base
  belongs_to :courses_user
  belongs_to :survey_assignment
  belongs_to :course

  scope :active, -> { where(dismissed: false) }
  scope :completed, -> { where(completed: true) }
  scope :dismissed, -> { where(completed: true) }

  def send_email
    # In these environments only send emails to the users specified in ENV['survey_test_email']
    return if ['development', 'staging'].include?(Rails.env) && !ENV['survey_test_email'].split(',').include?(user.email)
    SurveyMailer.notification(self).deliver_now unless email_sent
    update_attribute('email_sent', true)
  end

  def survey_assignment
    SurveyAssignment.find(survey_assignment_id)
  end

  def survey
    survey_assignment.survey
  end

  def user
    CoursesUsers.find(courses_user_id).user
  end

  def course
    Course.find(course_id)
  end
end
