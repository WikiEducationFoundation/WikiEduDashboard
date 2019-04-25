# frozen_string_literal: true

#= Helpers for tickets
module TicketsHelper
  def sender_for_message(message)
    message.sender&.real_name || message.sender&.username || message.details[:sender_email]
  end

  def successful_replies_in_reverse(_ticket, recipient)
    successful_messages = @ticket.messages.reject do |message|
      message.details[:delivery_failed]
    end

    reversed_messages = successful_messages.reverse[1..-1]

    reversed_messages.select do |message|
      recipient.admin? || message.kind == TicketDispenser::Message::Kinds::REPLY
    end
  end
end
