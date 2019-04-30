# frozen_string_literal: true

class TicketNotificationMailer < ApplicationMailer
  add_template_helper(TicketsHelper)

  def self.notify_of_message(opts)
    return unless Features.email?
    notify(opts).deliver_now
  end

  def notify(course:, message:, recipient:, sender:, bcc_to_salesforce:)
    @course = course
    @message = message
    @ticket = message.ticket
    @recipient = recipient
    @sender = sender
    @sender_name = @sender.real_name || @sender.username
    @bcc_to_salesforce = bcc_to_salesforce

    @course_link = "https://#{ENV['dashboard_url']}/courses/#{@course.slug}" if @course
    @ticket_dashboard_link = "https://#{ENV['dashboard_url']}/tickets/dashboard"

    mail(to: @recipient.email,
         bcc: bcc,
         cc: carbon_copy,
         from: @sender.email,
         subject: email_subject,
         reply_to: @sender.email)
  end

  private

  def bcc
    @bcc_to_salesforce ? ENV['SALESFORCE_BCC_EMAIL'] : nil
  end

  def carbon_copy
    cc = @message.details[:cc]
    cc&.map { |entry| entry[:email] }
  end

  def email_subject
    subject_prefix = @course ? "#{@course.title}: " : ''
    subject_prefix + 'Response to your help request'
  end
end
