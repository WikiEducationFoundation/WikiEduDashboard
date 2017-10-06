# frozen_string_literal: true

class UntrainedStudentsAlertMailer < ApplicationMailer
  def email(alert)
    return unless Features.email?
    @alert = alert
    set_course_and_users
    params = { to: @instructors.pluck(:email),
               cc: @admins.pluck(:email),
               bcc: @alert.bcc_to_salesforce_email,
               subject: @alert.main_subject }
    params[:reply_to] = @alert.reply_to unless @alert.reply_to.nil?
    mail(params)
  end

  private

  def set_course_and_users
    @course = @alert.course
    @admins = @course.nonstudents.where(permissions: 1)
    @instructors = @course.instructors
    @greeted_users = @instructors.pluck(:username).to_sentence # eg, "User, User2, and User3"
  end
end
