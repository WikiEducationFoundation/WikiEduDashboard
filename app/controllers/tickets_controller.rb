# frozen_string_literal: true

class TicketsController < ApplicationController
  before_action :require_admin_permissions

  # Load React App
  def dashboard
    @admins = User.admin.map { |user| [user.username, user.id] }
  end

  def notify
    notify_of_message
  end

  def notify_owner
    notify_of_message(true)
  end

  private

  def notify_of_message(owner=false)
    message = TicketDispenser::Message.find(notification_params[:message_id])
    sender_email = message.details[:sender_email]
    sender = User.find(notification_params[:sender_id]) || sender_email
    ticket = message.ticket
    course = ticket.project
    recipient = owner ? ticket.owner : ticket.reply_to || User.new(email: sender_email)

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

  def notification_params
    params.permit(:cc, :message_id, :sender_id)
  end
end
