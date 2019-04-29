# frozen_string_literal: true

class DidYouKnowAlertMailer < ApplicationMailer
  def self.send_dyk_email(alert)
    return unless Features.email?
    email(alert)
  end

  def email(alert)
    @alert = alert
    set_course_and_creators
    return if @instructors.empty?
    params = { to: @instructors.pluck(:email),
             subject: @alert.main_subject }
    params[:reply_to] = @alert.reply_to unless @alert.reply_to.nil?
    mail(params)
  end

  private

  def set_course_and_creators
    @course = @alert.course
    @instructors = @course.instructors
  end
end
