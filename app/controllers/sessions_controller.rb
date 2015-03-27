class SessionsController < ApplicationController
  def create
    # @access_token = request.env["omniauth.auth"]["extra"]["access_token"]
    # @user = User.find_or_create_from_auth_hash(request.env['omniauth.auth'])
    render plain: "Logged in as #{request.env['omniauth.auth']['info']['name']}!"
  end
end
