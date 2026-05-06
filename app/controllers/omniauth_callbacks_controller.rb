# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/importers/user_importer"

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
      restore_lti_origin
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

  # If the user was bounced through Wikipedia OAuth from an LTI launch,
  # /lti/escape posted the ltik into omniauth.params via a hidden form
  # field. Resume the launch by rewriting omniauth.origin so
  # after_sign_in_path_for sends them back to /lti?ltik=... — at top
  # level, since the escape flow already broke out of the iframe.
  #
  # Session can't be used as the carrier here: cookies set inside the
  # Canvas iframe are partitioned away from the top-level cookie jar,
  # so they aren't visible after the iframe→top transition.
  def restore_lti_origin
    ltik = request.env.dig('omniauth.params', 'ltik').presence
    return if ltik.blank?

    request.env['omniauth.origin'] = "/lti?ltik=#{CGI.escape(ltik)}"
  end
end
