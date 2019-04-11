# frozen_string_literal: true

class TicketNotificationMailer < ApplicationMailer
  def self.notify_of_message(course, message, recipient, sender)
    return unless Features.email?
    notify(course, message, recipient, sender).deliver_now
  end

  def notify(course, message, recipient, sender)
    @course = course
    @message = message
    @ticket = message.ticket
    @recipient = recipient
    @sender = sender
    @sender_name = @sender.real_name || @sender.username
    subject_prefix = @course ? "#{course.title}: " : ''

    @course_link = "https://#{ENV['dashboard_url']}/courses/#{@course.slug}" if @course
    @ticket_dashboard_link = "https://#{ENV['dashboard_url']}/tickets/dashboard"
    mail(to: @recipient.email,
         from: @sender.email,
         subject: subject_prefix + 'Response to your help request',
         reply_to: @sender.email)
  end
end
