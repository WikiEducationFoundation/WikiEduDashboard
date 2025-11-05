# frozen_string_literal: true

class AiEditAlertMailer < ApplicationMailer
  def self.send_emails(alert)
    return unless Features.email?
    email(alert).deliver_now
  end

  def email(alert)
    @alert = alert
    @course = @alert.course
    return unless @course

    to_email = @alert.content_experts.to_a
    to_email += [@alert.user]
    to_email += @alert.course.instructors.to_a

    emails = to_email.filter_map(&:email)
    return if emails.empty?

    subject = @alert.main_subject

    @course_link = "https://#{ENV['dashboard_url']}/courses/#{@course.slug}"

    mail(template_name: @alert.email_template_name, to: emails, subject:)
  end
end
