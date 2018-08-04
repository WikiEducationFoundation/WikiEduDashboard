# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_course_edits"
require_dependency "#{Rails.root}/lib/importers/user_importer"
require_dependency "#{Rails.root}/app/workers/remove_assignment_worker"
require_dependency "#{Rails.root}/app/workers/update_course_worker"

#= Controller for user functionality
class UsersController < ApplicationController
  respond_to :html, :json

  before_action :require_participating_user, only: [:enroll]
  before_action :require_signed_in, only: [:update_locale]
  before_action :require_admin_permissions, only: [:index]

  layout 'admin', only: [:index]

  def signout
    if current_user.nil?
      redirect_to '/'
    else
      current_user.update_attributes(wiki_token: nil, wiki_secret: nil)
      redirect_to true_destroy_user_session_path
    end
  end

  def update_locale
    locale = params[:locale]

    unless I18n.available_locales.include?(locale.to_sym)
      render json: { message: 'Invalid locale' }, status: :unprocessable_entity
      return
    end

    current_user.locale = locale
    current_user.save!
    render json: { success: true }
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
