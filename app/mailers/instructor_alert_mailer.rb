# frozen_string_literal: true

class InstructorAlertMailer < ApplicationMailer
  def email(alert)
    return unless Features.email?
    @alert = alert
    set_course_and_creators
    if @instructors.present?
      params = { to: @instructors.pluck(:email),
               subject: @alert.main_subject }
      params[:reply_to] = @alert.reply_to unless @alert.reply_to.nil?
      mail(params)
    end
  end

  private

  def set_course_and_creators
    @course = @alert.course
    @instructors = @course.instructors
  end
end
