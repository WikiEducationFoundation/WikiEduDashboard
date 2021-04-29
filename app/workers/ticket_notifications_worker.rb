# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/tickets/ticket_notification_emails"

class TicketNotificationsWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def perform
    TicketNotificationEmails.notify
  end
end
