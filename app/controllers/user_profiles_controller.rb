# frozen_string_literal: true

class UserProfilesController < ApplicationController
  respond_to :html, :json

  before_action :set_user
  before_action :set_user_profile, only: [:update]
  before_action :require_write_permissions, only: [:update]

  def show
    if @user
      @courses_users = @user.courses_users.includes(:course).where(courses: { private: false })
      @user_profile = UserProfile.new(user_id: @user.id)
    else
      flash[:notice] = 'User not found'
      redirect_to controller: 'dashboard', action: 'index'
    end
  end

  def update
    @user_profile.update! user_profile_params

    flash[:notice] = 'Profile Updated'
    redirect_to controller: 'user_profiles', action: 'show'
  end

  def stats
    @individual_stats_presenter = IndividualStatisticsPresenter.new(user: @user)
    @courses_list = public_courses.where('courses_users.role = ?',
                                        CoursesUsers::Roles::INSTRUCTOR_ROLE)
    @courses_presenter = CoursesPresenter.new(current_user: current_user,
                                              courses_list: @courses_list)
  end

  def stats_graphs
    @individual_stats_presenter = IndividualStatisticsPresenter.new(user: @user)
    @courses_list = public_courses.where('courses_users.role = ?',
                                        CoursesUsers::Roles::INSTRUCTOR_ROLE)
    @courses_presenter = CoursesPresenter.new(current_user: current_user,
                                              courses_list: @courses_list)
  end

  private

  def public_courses
    @user.courses.nonprivate
  end

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
