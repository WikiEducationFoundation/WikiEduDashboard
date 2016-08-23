# frozen_string_literal: true
class SurveyMailer < ApplicationMailer
  def self.send_notification(notification)
    instructor_survey_notification(notification).deliver_now
  end

  def self.send_follow_up(notification)
    instructor_survey_follow_up(notification).deliver_now
  end

  def instructor_survey_notification(notification)
    return unless Features.email?
    set_ivars(notification)
    mail(to: @user.email, subject: "A survey is available for your course, '#{@course.title}'")
  end

  def instructor_survey_follow_up(notification)
    return unless Features.email?
    set_ivars(notification)
    mail(to: @user.email,
         subject: "Reminder: A survey is available for your course, '#{@course.title}'")
  end

  def student_learning_notification(notification)
  end

  def student_learning_follow_up(notification)
  end

  private

  def set_ivars(notification)
    @notification = notification
    @user = notification.user
    @survey = notification.survey
    @course = notification.course
  end
end
