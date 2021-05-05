# frozen_string_literal: true

class TicketNotificationEmails
  def self.notify
    new
  end

  def initialize
    User.admin.each do |admin|
      notify_of_open_tickets(admin)
    end
  end

  def notify_of_open_tickets(admin)
    open_tickets = TicketDispenser::Ticket.open_tickets.where(owner: [admin, nil])
    return unless open_tickets.any?
    TicketNotificationMailer.notify_of_open_tickets(tickets: open_tickets, owner: admin)
  end
end
