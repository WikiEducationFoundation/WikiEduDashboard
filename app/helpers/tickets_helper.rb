# frozen_string_literal: true

#= Helpers for tickets
module TicketsHelper
  def sender_for_message(message)
    message.sender&.real_name || message.sender&.username || message.details[:sender_email]
  end

  def successful_replies_in_reverse(ticket, recipient)
    successful_messages = ticket.messages.reject do |message|
      details = message.details || {}
      details[:delivered].nil? && details[:delivery_failed]
    end

    reversed_messages = successful_messages.reverse

    reversed_messages.select do |message|
      recipient.admin? || message.reply?
    end
  end
end
