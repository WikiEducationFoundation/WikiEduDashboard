# frozen_string_literal: true
class SurveyMailer < ApplicationMailer
  ################
  # Entry points #
  ################

  def self.send_notification(notification)
    return unless Features.email?
    email_template = notification.survey_assignment.email_template
    raise UnknownEmailTemplateError unless TEMPLATES.include?(email_template)
    send("#{email_template}_notification", notification).deliver_now
  end

  def self.send_follow_up(notification)
    return unless Features.email?
    email_template = notification.survey_assignment.email_template
    raise UnknownEmailTemplateError unless TEMPLATES.include?(email_template)
    send("#{email_template}_follow_up", notification).deliver_now
  end

  #############
  # Templates #
  #############
  TEMPLATES = [
    'instructor_survey',
    'student_learning_preassessment',
  ].freeze

  def instructor_survey_notification(notification)
    set_ivars(notification)
    mail(to: @user.email, subject: "A survey is available for your course, '#{@course.title}'")
  end

  def instructor_survey_follow_up(notification)
    set_ivars(notification)
    mail(to: @user.email,
         subject: "Reminder: A survey is available for your course, '#{@course.title}'")
  end

  def student_learning_preassessment_notification(notification)
    set_ivars(notification)
    mail(to: @user.email, subject: "Take our assessment!")
  end

  def student_learning_preassessment_follow_up(notification)
    set_ivars(notification)
    mail(to: @user.email, subject: "Reminder: Take our assessment!")
  end

  ###########
  # Helpers #
  ###########

  class UnknownEmailTemplateError < StandardError; end

  private

  def set_ivars(notification)
    @notification = notification
    @user = notification.user
    @survey = notification.survey
    @course = notification.course
  end
end
