# frozen_string_literal: true
class UserProfilesController < ApplicationController
  respond_to :html, :json

  before_action :set_user
  before_action :set_user_profile, only: [:update, :destroy]
  before_action :require_write_permissions, only: [:update, :destroy]

  def show
    if @user
      @courses_users = @user.courses_users
      @courses_list = @user.courses.where('courses_users.role = ?', CoursesUsers::Roles::INSTRUCTOR_ROLE)
      @courses_presenter = CoursesPresenter.new(current_user: current_user, courses_list: @courses_list)
      @individual_stats_presenter = IndividualStatisticsPresenter.new(user: @user)
      @user_profile = UserProfile.new(user_id: @user.id)
      @editable = current_user == @user
    else
      flash[:notice] = 'User not found'
      redirect_to controller: 'dashboard', action: 'index'
    end
  end

  def update
    if @user_profile.update(user_profile_params)
      flash[:notice] = 'Profile Updated'
      redirect_to controller: 'user_profiles', action: 'show'
    end
  end

  def stats_data
    @individual_stats_presenter = IndividualStatisticsPresenter.new(user: @user)
    @courses_list = @user.courses.where('courses_users.role = ?', CoursesUsers::Roles::INSTRUCTOR_ROLE)
    @courses_presenter = CoursesPresenter.new(current_user: current_user, courses_list: @courses_list)
  end

  def destroy
    @user_profile.destroy
  end

  private

  def require_write_permissions
    return if current_user == @user

    exception = ActionController::InvalidAuthenticityToken.new('Unauthorized')
    raise exception
  end

  def user_profile_params
    params.require(:user_profile).permit(:bio, :image, :location, :institution)
  end

  def set_user
    # Per MediaWiki convention, underscores in username urls represent spaces
    username = params[:username].tr('_', ' ')
    @user = User.find_by_username(username)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_user_profile
    @user_profile = @user.user_profile
    @user_profile = @user.create_user_profile if @user_profile.nil?
  end
end
