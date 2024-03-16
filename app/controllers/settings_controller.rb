# frozen_string_literal: true

##
# controller actions for super users to interact with app wide settings
class SettingsController < ApplicationController # rubocop:disable Metrics/ClassLength
  before_action :require_admin_permissions
  before_action :require_super_admin_permissions,
                only: [:upgrade_admin, :downgrade_admin,
                       :upgrade_special_user, :downgrade_special_user,
                       :update_salesforce_credentials, :update_impact_stats,
                       :update_site_notice, :toggle_site_notice]

  layout 'application'

  def index; end

  def all_admins
    respond_to do |format|
      format.json do
        # display all admins and super admins
        admins = User.where(permissions: 1)
                     .or(User.where(permissions: 3))

        render json: { admins: }
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

  def upgrade_special_user
    update_special_user do
      attempt_special_user_upgrade do |resp|
        render resp
        return
      end
    end
  end

  def downgrade_special_user
    update_special_user do
      attempt_special_user_downgrade do |resp|
        render resp
        return
      end
    end
  end

  def special_users
    @special_users = SpecialUsers.special_users.transform_values do |username|
      User.where(username:)
    end
  end

  def update_special_user
    respond_to do |format|
      format.json do
        @user = User.find_by(username: special_user_params[:username])
        @position = special_user_params[:position]
        ensure_user_exists(special_user_params[:username]) { return }
        unless SpecialUsers.respond_to? @position
          return render json: { message: 'position is invalid' },
                        status: :unprocessable_entity
        end
        yield
      end
    end
  end

  def update_salesforce_credentials
    SalesforceCredentials.update(params[:password], params[:token])
    render json: { message: 'Salesforce credentials updated.' }, status: :ok
  end

  def course_creation
    Deadlines.reload_setting_record
    render json: Deadlines.student_program
  end

  def update_course_creation
    Deadlines.update_student_program(
      recruiting_term: params[:recruiting_term],
      deadline: params[:deadline],
      before_deadline_message: params[:before_deadline_message],
      after_deadline_message: params[:after_deadline_message]
    )
    render json: { message: 'Course creation settings updated.' }, status: :ok
  end

  def default_campaign
    render json: { default_campaign: CampaignsPresenter.default_campaign_slug }
  end

  def update_default_campaign
    CampaignsPresenter.update_default_campaign(params[:default_campaign])
    render json: { message: 'Default campaign updated.' }, status: :ok
  end

  def update_impact_stats
    updated_stats = params[:impactStats]
    updated_stats.each do |key, value|
      Setting.set_hash('impact_stats', key, value)
    end
    Rails.cache.delete('impact_stats')
    render json: { message: 'Impact Stats Updated Successfully.' }, status: :ok
  end

  def fetch_site_notice
    render json: { site_notice: ENV['sitenotice'] }, status: :ok
  end

  def update_site_notice
    updated_site_notice = params[:siteNotice]
    Setting.set_hash('site_notice', 'message', updated_site_notice)
    Rails.cache.delete('site_notice')
    set_site_notice
    render json: { message: 'Site Notice Updated Successfully.' }, status: :ok
  end

  def toggle_site_notice
    if ENV['sitenotice'].blank?
      set_site_notice
    else
      ENV['sitenotice'] = ''
    end
    render json: { message: 'Site Notice Toggled Successfully.' }, status: :ok
  end

  private

  def set_site_notice
    ENV['sitenotice'] = current_site_notice['message']
  end

  def current_site_notice
    Rails.cache.fetch('site_notice') do
      site_notice = Setting.find_by(key: 'site_notice')&.value.presence
      site_notice
    end
  end

  def username_param
    params.require(:user).permit(:username)
  end

  def special_user_params
    params.require(:special_user).permit(:username, :position)
  end

  ##
  # handles shared functionality for upgrading and demoting admin status
  def update_admin
    respond_to do |format|
      format.json do
        @user = User.find_by username: username_param[:username]
        ensure_user_exists(username_param[:username]) { return }
        yield
      end
    end
  end

  ##
  # attempt to upgrade `user` to special_user unless they already are one.
  def attempt_special_user_upgrade
    # Check if the user already has the position
    if SpecialUsers.is?(@user, @position)
      message = I18n.t(
        'settings.special_users.new.already_is',
        username: @user.username,
        position: @position
      )
      yield json: { message: }, status: 422
    end
    SpecialUsers.set_user(@position, @user.username)
    message = I18n.t(
      'settings.special_users.new.elevate_success',
      username: @user.username,
      position: @position
    )
    yield json: { message: }, status: 200
  end

  ##
  # attempt to downgrade `special_user` to user unless they already are one.
  def attempt_special_user_downgrade
    # Check if the user already has the position
    unless SpecialUsers.is?(@user, @position)
      message = I18n.t(
        'settings.special_users.new.already_is_not',
        username: @user.username,
        position: @position
      )
      yield json: { message: }, status: 422
    end
    SpecialUsers.remove_user(@position, username: @user.username)
    message = I18n.t(
      'settings.special_users.remove.demote_success',
      username: @user.username,
      position: @position
    )
    yield json: { message: }, status: 200
  end

  ##
  # attempt to upgrade `user` to admin unless they already are one.
  def attempt_admin_upgrade
    # if user was already an admin or super admin
    if @user.admin?
      message = I18n.t('settings.admin_users.new.already_admin', username: @user.username)
      yield json: { message: }, status: 422
    end
    # happy path!
    @user.update permissions: User::Permissions::ADMIN
    message = I18n.t('settings.admin_users.new.elevate_success', username: @user.username)
    yield json: { message: }, status: 200
  end

  ##
  # attempt to upgrade `user` to instructor unless they already are one.
  def attempt_admin_downgrade
    # already an instructor
    if @user.instructor_permissions?
      message = I18n.t('settings.admin_users.remove.already_instructor', username: @user.username)
      yield json: { message: }, status: 422
    end

    if @user.super_admin?
      message = I18n.t('settings.admin_users.remove.no_super_admin')
      yield json: { message: }, status: 422
    end

    # happy path
    @user.update permissions: User::Permissions::INSTRUCTOR
    message = I18n.t('settings.admin_users.remove.demote_success', username: @user.username)
    yield json: { message: }, status: 200
  end

  ##
  # yield up an error message if no user is found.
  def ensure_user_exists(username)
    return unless @user.nil?
    render json: { message: I18n.t('courses.error.user_exists', username:) },
           status: :not_found
    yield
  end
end
