class SurveyNotification < ActiveRecord::Base
  belongs_to :courses_user
  belongs_to :survey_assignment
  belongs_to :course

  def send_emails_and_create_notifications
    @survey = self.survey_assignment.survey
    @user = self.courses_user.user
    @course = self.course
    
  end
end