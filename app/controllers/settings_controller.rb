# frozen_string_literal: true

##
# controller actions for super users to interact with app wide settings
class SettingsController < ApplicationController
  before_action :require_super_admin_permissions

  ##
  # for now, this controller provides a way for super admins to add and remove admins

  layout 'application'

  def index; end

  def all_admins
    respond_to do |format|
      format.json do
        # display all admins and super admins
        admins = User.where(permissions: 1)
                     .or(User.where(permissions: 3))

        render json: { admins: admins }
      end
    end
  end

  def upgrade_admin
    update_admin do
      attempt_admin_upgrade do |resp|
        render resp
        return
      end
    end
  end

  def downgrade_admin
    update_admin do
      attempt_admin_downgrade do |resp|
        render resp
        return
      end
    end
  end

  private

  def username_param
    params.require(:user).permit(:username)
  end

  ##
  # handles shared functionality for upgrading and demoting admin status
  def update_admin
    respond_to do |format|
      format.json do
        @user = User.find_by username: username_param[:username]
        ensure_user_exists(params[:username]) { return }
        yield
      end
    end
  end

  ##
  # attempt to upgrade `user` to admin unless they already are one.
  def attempt_admin_upgrade
    # if user was already an admin or super admin
    if @user.admin?
      message = I18n.t('settings.admin_users.new.already_admin', username: @user.username)
      yield json: { message: message }, status: 422
    end
    # happy path!
    @user.update_attributes permissions: User::Permissions::ADMIN
    message = I18n.t('settings.admin_users.new.elevate_success', username: @user.username)
    yield json: { message: message }, status: 200
  end

  ##
  # attempt to upgrade `user` to instructor unless they already are one.
  def attempt_admin_downgrade
    # already an instructor
    if @user.instructor_permissions?
      message = I18n.t('settings.admin_users.remove.already_instructor', username: @user.username)
      yield json: { message: message }, status: 422
    end

    if @user.super_admin?
      message = I18n.t('settings.admin_users.remove.no_super_admin')
      yield json: { message: message }, status: 422
    end

    # happy path
    @user.update_attributes permissions: User::Permissions::INSTRUCTOR
    message = I18n.t('settings.admin_users.remove.demote_success', username: @user.username)
    yield json: { message: message }, status: 200
  end

  ##
  # yield up an error message if no user is found.
  def ensure_user_exists(username)
    return unless @user.nil?
    render json: { message: I18n.t('courses.error.user_exists', username: username) },
           status: :not_found
    yield
  end
end
