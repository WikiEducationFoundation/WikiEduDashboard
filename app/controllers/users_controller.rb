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
    @users = if params[:email].present?
               User.search_by_email(params[:email])
             elsif params[:real_name].present?
               User.search_by_real_name(params[:real_name])
             else
               User.instructor.limit(20)
                   .order(created_at: :desc)
             end
  end
end
