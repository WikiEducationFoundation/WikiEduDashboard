# frozen_string_literal: true

#= Helpers for tickets
module TicketsHelper
  def sender_for_message(message)
    message.sender&.real_name || message.sender&.username || message.details[:sender_email]
  end
end
