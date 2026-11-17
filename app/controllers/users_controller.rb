# frozen_string_literal: true
#= Controller for user functionality
class UsersController < ApplicationController
  respond_to :html, :json

  before_action :require_admin_permissions, only: [:index]

  layout 'admin', only: [:index]

  # What Devise's sessions#destroy does, after clearing the wiki credentials.
  # This used to redirect there, but a redirect can only be followed by GET.
  def signout
    if current_user
      current_user.update(wiki_token: nil, wiki_secret: nil)
      sign_out
      flash[:notice] = t('devise.sessions.signed_out')
    end
    redirect_to after_sign_out_path_for(:user)
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
