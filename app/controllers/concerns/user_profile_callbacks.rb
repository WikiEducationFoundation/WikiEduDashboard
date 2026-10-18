# frozen_string_literal: true

module UserProfileCallbacks
  extend ActiveSupport::Concern

  private

  def require_write_permissions
    return if current_user == @user
    raise ActionController::InvalidAuthenticityToken, 'Unauthorized'
  end

  def require_email_preferences_token
    return if @user_profile.email_preferences_token == params[:token]
    raise ActionController::InvalidAuthenticityToken, 'Unauthorized'
  end

  def user_profile_params
    params.require(:user_profile).permit(:bio, :image, :location, :institution, :image_file_link)
  end

  def user_email_params
    params.require(:email).permit(:email)
  end

  def email_must_be_present_for_instructors
    return unless current_user.active_course_instructor?
    submitted_email = user_email_params[:email].to_s.strip

    return if submitted_email.present?

    @user.errors.add(:email, :blank, message: I18n.t('users.email_required_instructor'))
    flash[:error] = I18n.t('users.email_required_instructor')
  end

  def user_profile_redirect
    redirect_to controller: 'user_profiles', action: 'show', username: @user.username
  end

  def set_user
    # Per MediaWiki convention, underscores in username urls represent spaces
    username = CGI.unescape(params[:username]).tr('_', ' ')
    @user = User.find_by(username:)
  end

  def set_user_profile
    @user_profile = @user.user_profile
    @user_profile = @user.create_user_profile if @user_profile.nil?
  end
end
