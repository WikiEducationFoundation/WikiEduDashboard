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

    @course_link = "https://#{ENV['dashboard_url']}/courses/#{@course.slug}" if @course
    @ticket_dashboard_link = "https://#{ENV['dashboard_url']}/tickets/dashboard"

    mail(to: @recipient.email,
         cc: carbon_copy,
         from: @sender.email,
         subject: email_subject,
         reply_to: @sender.email)
  end

  private

  def carbon_copy
    cc = @message.details[:cc]
    cc&.map(&:email)
  end

  def email_subject
    subject_prefix = @course ? "#{@course.title}: " : ''
    subject_prefix + 'Response to your help request'
  end
end
