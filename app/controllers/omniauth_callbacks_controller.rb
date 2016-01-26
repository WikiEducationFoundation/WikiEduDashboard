require "#{Rails.root}/lib/importers/user_importer"

#= Controller for OmniAuth authentication callbacks
class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Devise::Controllers::Rememberable

  def mediawiki
    @user = UserImporter.from_omniauth(request.env['omniauth.auth'])

    return handle_jwt_error if request.env['JWT_ERROR']

    if @user.persisted?
      remember_me @user
      sign_in_and_redirect @user
    else
      redirect_to root_url
    end
  end

  protected

  def handle_jwt_error
    Raven.capture_message 'OAuth login failed',
                          extra: { jwt_data: request.env['JWT_DATA'].body }
    return redirect_to errors_login_error_path
  end
end
