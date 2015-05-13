#= Root-level controller for the application
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  rescue_from ActionController::InvalidAuthenticityToken do
    respond_to do |format|
      format.json do
        render plain: t('error_401.explanation'),
               status: :unauthorized
      end
    end
  end

  before_action :set_locale

  def require_permissions
    course = Course.find_by_slug(params[:id])
    exception = ActionController::InvalidAuthenticityToken.new('Unauthorized')
    raise exception unless user_signed_in? && current_user.can_edit?(course)
  end

  def course_slug_path(slug)
    show_path(id: slug)
  end
  helper_method :course_slug_path

  def rtl?
    tag = I18n::Locale::Tag::Rfc4646.tag(I18n.locale)
    tag.language.in? %w(ar dv fa he ku ps sd ug ur yi)
  end
  helper_method :rtl?

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def default_url_options(options = {})
    if I18n.locale != I18n.default_locale
      { locale: I18n.locale }.merge options
    else
      options
    end
  end

  def new_session_path(scope)
    new_user_session_path
  end
  helper_method :new_session_path
end
