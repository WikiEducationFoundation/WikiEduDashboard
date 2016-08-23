# frozen_string_literal: true
# Preview all emails at http://localhost:3000/rails/mailers/survey_mailer
class SurveyMailerPreview < ActionMailer::Preview
  def instructor_survey_notification
    SurveyMailer.instructor_survey_notification(SurveyNotification.last)
  end

  def instructor_survey_follow_up
    SurveyMailer.instructor_survey_follow_up(SurveyNotification.last)
  end

  def student_learning_preassessment_notification
    SurveyMailer.student_learning_preassessment_notification(SurveyNotification.last)
  end

  def student_learning_preassessment_follow_up
    SurveyMailer.student_learning_preassessment_follow_up(SurveyNotification.last)
  end
end
