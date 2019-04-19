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

    message.details[:delivered] = Time.zone.now
    message.save
    render json: { success: :ok }
  rescue StandardError
    message.details[:delivery_failed] = Time.zone.now
    message.save
    render json: { message: 'Email could not be sent. :(' },
          status: :unprocessable_entity
  end

  private

  def notification_params
    params.permit(:cc, :message_id, :sender_id)
  end
end
