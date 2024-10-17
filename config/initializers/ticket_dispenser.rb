# frozen_string_literal: true

require 'ticket_dispenser'

Rails.application.config.to_prepare do
  TicketDispenser::Ticket.class_eval do
    def sender
      message = messages.first
      return {} unless message
      
      user = message.sender if message
      return { email: message.details[:sender_email] } if user.nil?
      
      {
        username: user.username,
        real_name: user.real_name,
        email: user.email,
        role: user.highest_role(project)
      }
    end
  end

  TicketDispenser::Message.class_eval do
    def serialized_sender
      return {} if sender.nil?
      {
        sender_id: sender_id,
        real_name: sender.real_name
      }
    end
  end
end
