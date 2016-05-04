class SurveyMailer < ApplicationMailer
  def notification(notification)
    return unless Features.email?
    set_ivars(notification)
    mail(to: @user.email, subject: "A survey is available for your course, '#{@course.title}'")
  end

  def follow_up(notification)
    return unless Features.email?
    set_ivars(notification)
    mail(to: @user.email, subject: "Reminder: A survey is available for your course, '#{@course.title}'")
  end

  private

  def set_ivars(notification)
    @notification = notification
    @user = notification.user
    @survey = notification.survey
    @course = notification.course
  end
end
