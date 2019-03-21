# frozen_string_literal: true

class TicketsController < ApplicationController
  before_action :require_admin_permissions

  # Load React App
  def dashboard; end

  def index
    render json: Ticket.all, status: :ok
  end

  private

  def ticket_params
    params.permit(:status, :course, :alert, :user)
  end
end
