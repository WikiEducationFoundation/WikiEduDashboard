# frozen_string_literal: true

# Controller for application's settings
class SettingsController < ApplicationController
  layout 'admin'
  before_action :require_super_admin_permissions
  # before_action :check_user_auth

  def index
    @settings = Setting.all
    @users = if params[:email].present?
               User.search_by_email(params[:email])
             elsif params[:real_name].present?
               User.search_by_real_name(params[:real_name])
             else
               User.admin.limit(20)
                   .order(created_at: :desc)
             end
  end

  def update
    @setting = Setting.find(params[:id])
    set = @setting.key
    @setting.value = setting_params[set]
    unless add_setting[:new_setting].empty?
      key = add_setting[:new_setting].parameterize.underscore.to_sym
      @setting.value[key] = add_setting[:setting_value] unless @setting.value.key?(key)
    end
    if @setting.changed?
      if @setting.save
        flash[:success] = true
        redirect_to settings_path
        return
      end
    else
      flash[:notice] = "No changes were made"
    end
    redirect_to settings_path
  end

  def destroy
    @setting = Setting.find(params[:id])
    key = params[:q].parameterize.underscore.to_sym
    @setting.value.delete(key)
    @setting.save

    redirect_to settings_path
  end

  private

  # def check_user_auth
  #   return if current_user&.admin?
  #   flash[:notice] = "You don't have access to that page."
  #   redirect_to root_path
  # end

  def require_super_admin_permissions
    # check_user_auth
    require_admin_permissions # or check_user_auth from above
    return if current_user == SpecialUsers.super_admin
    flash[:notice] = "You are not a Super Admin."
    redirect_to admin_index_path
  end

  def add_setting
    params.require(:setting).permit([:new_setting, :setting_value])
  end

  def setting_params
    params.permit(setting: {})[:setting].to_h
  end
end
