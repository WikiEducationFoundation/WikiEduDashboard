# frozen_string_literal: true

class TicketsController < ApplicationController
  before_action :require_admin_permissions

  # Load React App
  def dashboard; end

  def notify
    message = TicketDispenser::Message.find(notification_params[:message_id])
    sender = User.find(notification_params[:sender_id])

    ticket = message.ticket
    course = ticket.course
    recipient = ticket.reply_to

    TicketNotificationMailer.notify_of_message(course, message, recipient, sender)
    render json: { success: :ok }
  end

  private

  def notification_params
    params.permit(:course_id, :message_id, :recipient_id, :sender_id)
  end
end
