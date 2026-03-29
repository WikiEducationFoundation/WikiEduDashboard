# frozen_string_literal: true
#= Controller for user functionality
class UsersController < ApplicationController
  respond_to :html, :json

  before_action :require_admin_permissions, only: [:index]

  layout 'admin', only: [:index]

  def signout
    if current_user.nil?
      redirect_to '/'
    else
      current_user.update(wiki_token: nil, wiki_secret: nil)
      redirect_to true_destroy_user_session_path
    end
  end

  ####################################################
  # User listing page for Admins                     #
  ####################################################
  def index
    @query = params[:email].presence || params[:real_name].presence || params[:query]
    @users = if @query.present?
               User.search(@query)
             else
               User.instructor
             end
    @users = @users.order(created_at: :desc).limit(100)
    respond_with @users
  end
end
