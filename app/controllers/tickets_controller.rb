# frozen_string_literal: true

class TicketsController < ApplicationController
  before_action :require_admin_permissions

  # Load React App
  def dashboard; end
end
