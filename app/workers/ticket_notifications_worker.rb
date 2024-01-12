# frozen_string_literal: true
require_dependency Rails.root.join('lib/tickets/ticket_notification_emails')

class TicketNotificationsWorker
  include Sidekiq::Worker

  def perform
    TicketNotificationEmails.notify
  end
end
