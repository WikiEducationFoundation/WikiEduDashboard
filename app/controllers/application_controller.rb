gem 'browser'

# The application controller is the parent for all other controllers.
# It includes methods are relevant across the application, such as permissions
# and login.
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  rescue_from ActionController::InvalidAuthenticityToken do
    render plain: t('error_401.explanation'),
           status: :unauthorized
  end

  before_action :check_for_expired_oauth_credentials
  before_action :check_for_unsupported_browser
  before_action :check_onboarded

  force_ssl if: :ssl_configured?

  before_filter :set_locale_override
  include HttpAcceptLanguage::AutoLocale

  def after_sign_out_path_for(_resource_or_scope)
    '/'
  end

  def after_sign_in_path_for(_resource_or_scope)
    request.env['omniauth.origin'] || '/'
  end

  def check_onboarded
    return unless current_user
    return if current_user.onboarded
    return if request.fullpath.starts_with? onboarding_path
    return if request.fullpath.starts_with? onboard_path
    return if request.fullpath.starts_with? new_user_session_path
    return if request.fullpath.starts_with? destroy_user_session_path
    return if request.fullpath.starts_with? true_destroy_user_session_path
    redirect_to onboarding_path(return_to: request.fullpath)
  end

  def require_permissions
    course = Course.find_by_slug(params[:id])
    exception = ActionController::InvalidAuthenticityToken.new('Unauthorized')
    fail exception unless user_signed_in? && current_user.can_edit?(course)
  end

  def require_participating_user
    course = Course.find_by_slug(params[:id])
    exception = ActionController::InvalidAuthenticityToken.new('Unauthorized')
    fail exception unless user_signed_in? && current_user.role(course) >= 0
  end

  def check_for_expired_oauth_credentials
    return unless current_user && current_user.wiki_token == 'invalid'

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
    tag.language.in? %w(ar dv fa he ku ps sd ug ur yi)
  end
  helper_method :rtl?

  def new_session_path(_scope)
    new_user_session_path
  end
  helper_method :new_session_path

  private

  def ssl_configured?
    Rails.env.staging? || Rails.env.production?
  end

<<<<<<< 8b7e6eefa234f9af43b3dec7503f4a52d32f1c1f
  def set_locale_override
    if params[:locale]
      # Param takes precedence over language preferences from HTTP headers.
      http_accept_language.user_preferred_languages.unshift(params[:locale])
    end
  end
=======
>>>>>>> Add onboarding redirects
end
