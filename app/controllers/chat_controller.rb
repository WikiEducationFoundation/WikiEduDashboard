# frozen_string_literal: true
require "#{Rails.root}/lib/chat/rocket_chat"

class ChatController < ApplicationController
  respond_to :json
  before_action :require_signed_in

  def login
    chatter = RocketChat.new(user: current_user)
    chatter.create_chat_account unless current_user.chat_password
    credentials = chatter.login_credentials
    render json: { auth_token: credentials['authToken'], user_id: credentials['userId'] }
  end
end
