# frozen_string_literal: true
class Users::LocaleController < ApplicationController
  before_action :require_signed_in

  def update_locale
    @locale = params[:locale]
    validate_locale { return }

    save_user_locale

    if request.method == 'POST'
      render json: { success: true }
    else
      flash[:notice] = 'Locale preference updated!'
      redirect_to '/'
    end
  end

  private

  def validate_locale
    return if I18n.available_locales.include?(@locale.to_sym)

    render json: { message: 'Invalid locale' }, status: :unprocessable_entity
    yield
  end

  def save_user_locale
    current_user.locale = @locale
    current_user.save!
  end
end
