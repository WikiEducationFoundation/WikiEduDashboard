# frozen_string_literal: true

require 'ticket_dispenser'

Rails.application.config.to_prepare do
  TicketDispenser::Ticket.class_eval do
    def sender
      user = messages.first.sender if messages.first
      return {} if user.nil?
      {
        username: user.username,
        real_name: user.real_name,
        email: user.email,
        role: user.role(project)
      }
    end
  end
end
