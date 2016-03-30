class SurveyNotification < ActiveRecord::Base
  belongs_to :courses_user
  belongs_to :survey_assignment
  belongs_to :course

  def send_email
    if Rails.env['production']
      SurveyMailer.notification(user).deliver_now unless email_sent
    end

    if Rails.env['development'] && user.email == ENV['survey_test_email']
      SurveyMailer.notification(user).deliver_now unless email_sent
    end
    
    self.update_attribute('email_sent', true)
  end

  def survey
    SurveyAssignment.find(survey_assignment_id).survey
  end

  def user
    CoursesUsers.find(courses_user_id).user
  end

  def course
    Course.find(course_id)
  end
end