# frozen_string_literal: true

class TicketNotificationMailer < ApplicationMailer
  def self.notify_of_message(course, recipient, sender, message)
    return unless Features.email?
    notify(course, recipient, sender, message).deliver_now
  end

  def notify(course, message, recipient, sender)
    @course = course
    @message = message
    @recipient = recipient
    @sender = sender
    @sender_name = @sender.real_name || @sender.username

    @course_link = "https://#{ENV['dashboard_url']}/courses/#{@course.slug}"
    @ticket_dashboard_link = "https://#{ENV['dashboard_url']}/tickets/dashboard"
    @reference_code = "ref_m#{@message.id}_ref"
    mail(to: @recipient || recipient_email,
         from: @sender.email,
         subject: 'You received a response from your Wikipedia Expert')
  end
end
