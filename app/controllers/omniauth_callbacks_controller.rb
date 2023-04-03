# frozen_string_literal: true

require_dependency Rails.root.join('lib/importers/user_importer')

#= Controller for OmniAuth authentication callbacks
class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Devise::Controllers::Rememberable

  def mediawiki
    set_user_from_auth_hash { return }

    remember_me @user
    register_first_login

    # Here, we save the user from having to click 'Join' to confirm their enrollment.
    # If they started from an enroll link, redirect them directly to the enroll action.
    if returning_from_enroll_link?
      sign_in @user
      redirect_to "/courses/#{session['course_slug']}/enroll/#{session['enroll_code']}"
    else
      sign_in_and_redirect @user
    end
  end

  protected

  def set_user_from_auth_hash
    auth_hash = request.env['omniauth.auth']
    if login_failed?(auth_hash)
      handle_login_failure(auth_hash)
      return yield
    end

    @user = UserImporter.from_omniauth(auth_hash)
  end

  def handle_login_failure(auth_hash)
    Rails.logger.info "OAuth login failed: #{auth_hash}"
    Sentry.capture_message 'OAuth login failed',
                           level: 'warning',
                           extra: auth_hash[:extra][:raw_info]
    return redirect_to errors_login_error_path
  end

  def login_failed?(auth_hash)
    auth_hash[:extra]&.dig('raw_info', 'login_failed')
  end

  def register_first_login
    return if @user.first_login.present?
    @user.update(first_login: Time.now.utc)
  end

  def returning_from_enroll_link?
    return false unless session_course_slug
    origin = request.env['omniauth.origin']
    return false unless origin
    # the origin URL will include the course slug and the enroll code
    # if the user logged in from the 'enroll' view.
    origin[session_course_slug] && origin[session_enroll_code]
  end

  def session_course_slug
    session['course_slug']
  end

  def session_enroll_code
    session['enroll_code']
  end
end
