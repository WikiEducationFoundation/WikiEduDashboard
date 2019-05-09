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
    open_tickets = TicketDispenser::Ticket.open.where(owner: [admin, nil])
    next unless open_tickets.any?
    TicketNotificationMailer.notify(tickets: open_tickets, owner: admin)
  end
end
