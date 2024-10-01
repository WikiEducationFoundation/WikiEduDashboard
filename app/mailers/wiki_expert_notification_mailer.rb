# frozen_string_literal: true

class WikiExpertNotificationMailer < ApplicationMailer
  def self.send_email(alert)
    return unless Features.email?
    email(alert).deliver_now
  end

  def email(alert)
    @alert = alert
    @course = @alert.course
    @wiki_experts = @alert.wiki_experts_email
    @course_link = @alert.url

    mail(to: @wiki_experts, subject: @alert.main_subject)
  end
end
