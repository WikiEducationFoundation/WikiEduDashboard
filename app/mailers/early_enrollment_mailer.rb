# frozen_string_literal: true

class EarlyEnrollmentMailer < ApplicationMailer
  def self.send_email(alert)
    return unless Features.email?

    email(alert).deliver_now
  end

  def email(alert)
    @course = alert.course
    @course_link = alert.url

    mail(to: alert.wiki_experts_email, subject: alert.main_subject)
  end
end
