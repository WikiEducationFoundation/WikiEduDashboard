class SurveyMailer < ApplicationMailer
  def notification(notification)
    @notification = notification
    @user = notification.user
    @survey = notification.survey
    @course = notification.course
    mail(to: @user.email, subject: "A survey is available for your course. #{@course.title}")
  end
end
