# frozen_string_literal: true

##
# controller actions for super users to interact with app wide settings
class SettingsController < ApplicationController
  before_action :require_super_admin_permissions

  ##
  # for now, this controller provides a way for super admins to add and remove admins

  layout 'application'

  def index
  end

  def new
  end

  def create
  end

  def delete
  end

  def destroy
  end
end
