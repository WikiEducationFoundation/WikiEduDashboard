require "#{Rails.root}/lib/importers/user_importer"

#= Controller for OmniAuth authentication callbacks
class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Devise::Controllers::Rememberable

  def mediawiki
    auth_hash = request.env['omniauth.auth']
    return handle_login_failure(auth_hash) if auth_hash[:extra][:raw_info][:login_failed]

    @user = UserImporter.from_omniauth(auth_hash)

    if @user.persisted?
      remember_me @user
      sign_in_and_redirect @user
    else
      redirect_to root_url
    end
  end

  protected

  def handle_login_failure(auth_hash)
    Rails.logger.warn "OAuth login failed with jwt_data: #{auth_hash[:extra][:raw_info][:jwt_data]}"
    Raven.capture_message 'OAuth login failed',
                          extra: auth_hash
    return redirect_to errors_login_error_path
  end
end
