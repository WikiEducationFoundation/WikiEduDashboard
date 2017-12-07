# frozen_string_literal: true

# The application controller is the parent for all other controllers.
# It includes methods are relevant across the application, such as permissions
# and login.
class ApplicationController < ActionController::Base
  include Errors::RescueDevelopmentErrors if Rails.env == 'development' || Rails.env == 'test'
  include Errors::RescueErrors
  include Errors::AuthenticationErrors
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  force_ssl if: :ssl_configured?

  before_action :check_for_expired_oauth_credentials
  before_action :check_for_unsupported_browser
  before_action :check_onboarded
  before_action :set_locale
  before_action :set_paper_trail_whodunnit

  def after_sign_out_path_for(_resource_or_scope)
    '/'
  end

  def after_sign_in_path_for(_resource_or_scope)
    request.env['omniauth.origin'] || '/'
  end

  def check_onboarded
    return unless current_user
    return if Features.disable_onboarding? || current_user.onboarded
    full_path = request.fullpath
    non_redirect_paths = [onboarding_path,
                          onboard_path,
                          new_user_session_path,
                          destroy_user_session_path,
                          true_destroy_user_session_path]
    return if non_redirect_paths.any? { |path| full_path.starts_with? path }
    redirect_to onboarding_path(return_to: full_path)
  end

  def require_signed_in
    raise NotSignedInError unless user_signed_in?
  end

  def require_permissions
    require_signed_in
    course = Course.find_by_slug(params[:id])
    raise NotPermittedError unless current_user.can_edit? course
  end

  def require_admin_permissions
    require_signed_in
    raise NotAdminError unless current_user.admin?
  end

  def require_participating_user
    require_signed_in
    course = Course.find_by_slug(params[:id])
    # Course roles for non-students are greater than STUDENT_ROLE.
    # Non-participating users have the VISITOR_ROLE, which is below STUDENT_ROLE.
    return if current_user.role(course) >= CoursesUsers::Roles::STUDENT_ROLE
    raise ParticipatingUserError
  end

  def check_for_expired_oauth_credentials
    return unless current_user&.wiki_token == 'invalid'

    flash[:notice] = t('error.oauth_invalid')
    sign_out current_user
    redirect_to root_path
  end

  def check_for_unsupported_browser
    supported = !browser.ie? || browser.version.to_i >= 11
    flash[:notice] = t('error.unsupported_browser.explanation') unless supported
  end

  def course_slug_path(slug, args={})
    slug_parts = slug.split('/')
    show_path(args.merge(school: slug_parts[0], titleterm: slug_parts[1]))
  end
  helper_method :course_slug_path

  def rtl?
    tag = I18n::Locale::Tag::Rfc4646.tag(I18n.locale)
    tag.language.in? %w[ar dv fa he ku ps sd ug ur yi]
  end
  helper_method :rtl?

  def new_session_path(_scope)
    new_user_session_path
  end
  helper_method :new_session_path

  def can_administer?
    current_user&.admin?
  end

  private

  def ssl_configured?
    Rails.env.staging? || Rails.env.production?
  end

  def set_locale
    # Saved user locale takes precedence over language preferences from HTTP headers.
    preferred_locale_from_user
    # Param takes precedence over saved user local
    preferred_locale_from_param

    preferred_locale = http_accept_language.preferred_language_from I18n.available_locales
    I18n.locale = preferred_locale || I18n.default_locale
  end

  def preferred_locale_from_user
    return unless current_user&.locale
    http_accept_language.user_preferred_languages.unshift(current_user.locale)
  end

  def preferred_locale_from_param
    return unless params[:locale]
    http_accept_language.user_preferred_languages.unshift(params[:locale])
  end
end
