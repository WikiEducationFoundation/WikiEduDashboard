# frozen_string_literal: true

class PreexistingAiTextAlertMailer < ApplicationMailer
  def self.send_emails(alert)
    return unless Features.email?

    email(alert).deliver_now
  end

  # Same recipients as AiEditAlertMailer#email.
  def email(alert)
    @alert = alert
    @course = @alert.course
    return unless @course

    to_email = @alert.content_experts.to_a + [@alert.user] + @course.instructors.to_a
    emails = to_email.filter_map(&:email)
    return if emails.empty?

    @course_link = "https://#{ENV['dashboard_url']}/courses/#{@course.slug}"
    mail(to: emails, subject: @alert.main_subject)
  end
end
