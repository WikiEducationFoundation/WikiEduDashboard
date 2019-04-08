# frozen_string_literal: true

class TicketsController < ApplicationController
  before_action :require_admin_permissions

  # Load React App
  def dashboard
    @admins = User.admin.map { |user| [user.username, user.id] }
  end

  def notify
    message = TicketDispenser::Message.find(notification_params[:message_id])
    sender = User.find(notification_params[:sender_id])

    ticket = message.ticket
    course = ticket.project
    recipient = ticket.reply_to

    TicketNotificationMailer.notify_of_message(course, message, recipient, sender)
    render json: { success: :ok }
  end

  private

  def notification_params
    params.permit(:message_id, :sender_id)
  end
end
