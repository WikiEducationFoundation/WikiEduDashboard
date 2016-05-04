# Preview all emails at http://localhost:3000/rails/mailers/survey_mailer
class SurveyMailerPreview < ActionMailer::Preview
  def notification
    SurveyMailer.notification(SurveyNotification.last)
  end

  def followup
    SurveyMailer.follow_up(SurveyNotification.last)
  end
end
