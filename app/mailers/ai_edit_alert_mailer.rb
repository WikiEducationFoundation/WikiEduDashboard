# frozen_string_literal: true

class AiEditAlertMailer < ApplicationMailer
  def self.send_emails(alert, page_repeat:, user_repeat:)
    return unless Features.email?
    email(alert, page_repeat:, user_repeat:).deliver_now
  end

  def email(alert, page_repeat:, user_repeat:) # rubocop:disable Metrics/MethodLength
    @alert = alert
    @course = @alert.course
    return unless @course

    to_email = @alert.content_experts.to_a

    unless page_repeat
      to_email += [@alert.user]
      to_email += @alert.course.instructors.to_a
    end
    emails = to_email.filter_map(&:email)
    return if emails.empty?

    subject = if page_repeat
                @alert.repeat_page_subject
              elsif user_repeat
                @alert.repeat_user_subject
              else
                @alert.main_subject
              end

    @course_link = "https://#{ENV['dashboard_url']}/courses/#{@course.slug}"

    mail(to: emails, subject:)
  end
end
