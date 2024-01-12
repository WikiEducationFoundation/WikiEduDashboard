# frozen_string_literal: true

require_dependency Rails.root.join('lib/tickets/ticket_query_object')

class TicketsController < ApplicationController
  before_action :require_admin_permissions

  # Load React App
  def dashboard
    @admins = User.admin.map { |user| [user.username, user.id] }
  end

  def reply
    send_ticket_notification
  end

  def notify_owner
    send_ticket_notification(true)
  end

  def search
    @tickets = TicketQueryObject.new(params).search
    respond_to :json
  end

  private

  def send_ticket_notification(owner=false)
    set_ticket_details
    TicketNotificationMailer.notify_of_message(
      course: @course,
      message: @message,
      recipient: recipient(owner),
      sender: @sender,
      bcc_to_salesforce: notification_params[:bcc_to_salesforce]
    )

    @message.details[:delivered] = Time.zone.now
    @message.save
    render json: { success: :ok }
  rescue StandardError => e
    @message.details[:delivery_failed] = Time.zone.now
    @message.save
    raise e
  end

  def set_ticket_details
    @message = TicketDispenser::Message.find(notification_params[:message_id])
    @sender = User.find(notification_params[:sender_id])
    @ticket = @message.ticket
    @course = @ticket.project
  end

  def sender_email
    @sender_email ||= @message.ticket.messages.first.details[:sender_email]
  end

  def recipient(owner)
    owner ? @ticket.owner : (@ticket.reply_to || User.new(email: sender_email))
  end

  def notification_params
    params.permit(:bcc_to_salesforce, :cc, :message_id, :sender_id)
  end
end
