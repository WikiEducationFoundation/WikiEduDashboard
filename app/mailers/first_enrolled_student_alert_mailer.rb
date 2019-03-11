# frozen_string_literal: true

class FirstEnrolledStudentAlertMailer < ApplicationMailer
  def email(alert)
    return unless Features.email?
    @alert = alert
    set_course_and_users
    params = { to: @instructors.pluck(:email),
               bcc: @alert.bcc_to_salesforce_email,
               subject: @alert.main_subject }
    params[:reply_to] = @alert.reply_to unless @alert.reply_to.nil?
    mail(params)
  end

  private

  def set_course_and_users
    @course = @alert.course
    @instructors = @course.instructors
    # eg, "Full Name, User2, and Other Fullname"
    @greeted_users = @instructors.map { |user| user.real_name || user.username }.to_sentence
    @course_link = "https://#{ENV['dashboard_url']}/courses/#{@course.slug}"
    @students_link = "#{@course_link}/students"
    @timeline_link = "#{@course_link}/timeline"
  end
end
