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
  TEMPLATES = %w[
    custom
    instructor_survey
    student_learning_preassessment
  ].freeze

  def custom_notification(notification)
    prepare(notification)
    customize(notification)
    mail(to: @user.email, subject: @subject)
  end

  def custom_follow_up(notification)
    prepare(notification)
    customize(notification)
    mail(to: @user.email, subject: "Reminder: #{@subject}") do |format|
      format.text { render 'custom_notification' }
      format.html { render 'custom_notification' }
    end
  end

  def instructor_survey_notification(notification)
    prepare(notification)
    mail(to: @user.email, subject: "A survey is available for your course, '#{@course.title}'")
  end

  def instructor_survey_follow_up(notification)
    prepare(notification)
    mail(to: @user.email,
         subject: "Reminder: A survey is available for your course, '#{@course.title}'")
  end

  def student_learning_preassessment_notification(notification)
    prepare(notification)
    mail(to: @user.email, subject: 'Take the Wiki Ed Student Learning Survey')
  end

  def student_learning_preassessment_follow_up(notification)
    prepare(notification)
    mail(to: @user.email, subject: 'Reminder: Take the Wiki Ed Student Learning Survey')
  end

  ###########
  # Helpers #
  ###########

  class UnknownEmailTemplateError < StandardError; end

  private

  def prepare(notification)
    @notification = notification
    @user = notification.user
    @survey = notification.survey
    @course = notification.course
  end

  def customize(notification)
    @subject = notification.survey_assignment.custom_email_subject
    @headline = notification.survey_assignment.custom_email_headline
    @body_paragraphs = paragraphify(notification.survey_assignment.custom_email_body)
    @signature = notification.survey_assignment.custom_email_signature
  end

  def paragraphify(text)
    text.split("\r\n\r\n")
  end
end
