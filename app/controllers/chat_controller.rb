# frozen_string_literal: true

require "#{Rails.root}/lib/chat/rocket_chat"

class ChatController < ApplicationController
  respond_to :json
  before_action :require_signed_in, :check_chat_permission
  before_action :require_admin_permissions, only: [:enable_for_course]

  def login
    chatter = RocketChat.new(user: current_user)
    credentials = chatter.login_credentials # creates chat account if necessary
    render json: { auth_token: credentials['authToken'], user_id: credentials['userId'] }
  end

  def enable_for_course
    @course = Course.find(params[:course_id])
    EnableCourseChat.new(@course)
  end

  private

  def check_chat_permission
    return if Features.enable_chat?
    exception = ActionController::InvalidAuthenticityToken.new('Unauthorized')
    raise exception
  end
end
