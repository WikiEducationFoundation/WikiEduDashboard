# frozen_string_literal: true

class TicketsController < ApplicationController
  before_action :require_admin_permissions

  def index
    render json: {
      tickets: Ticket.all.as_json(include: :messages)
    }, status: :ok
  end

  private

  def ticket_params
    params.permit(:status, :course, :alert, :user)
  end
end
