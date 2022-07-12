# frozen_string_literal: true

class UserProfilesController < ApplicationController
  respond_to :html, :json

  before_action :set_user
  before_action :set_user_profile, only: [:update, :update_email_preferences]
  before_action :require_write_permissions, only: [:update]

  def show
    if @user
      @last_courses_user = @user.courses_users.includes(:course)
                                .where(courses: { private: false }).last
      @user_profile = UserProfile.new(user_id: @user.id)
    else
      flash[:notice] = 'User not found'
      redirect_to controller: 'dashboard', action: 'index'
    end
  end

  def update
    if params[:user_profile][:image] || params[:user_profile][:image_file_link]
      @user_profile.image.destroy
      @user_profile.image_file_link = nil
    end
    @user_profile.update! user_profile_params
    @user.update! user_email_params if valid_email?
    flash[:notice] = 'Profile Updated'
    redirect_to controller: 'user_profiles', action: 'show'
  end

  def stats
    @courses_users = @user.courses_users.includes(:course).where(courses: { private: false })
    @individual_stats_presenter = IndividualStatisticsPresenter.new(user: @user)
    @courses_list = public_courses
                    .where(courses_users: { role: CoursesUsers::Roles::INSTRUCTOR_ROLE })
    @courses_presenter = CoursesPresenter.new(current_user: current_user,
                                              courses_list: @courses_list)
    @user_uploads = CommonsUpload.where(user_id: @user.id).order(uploaded_at: :desc).first(20)
    @max_project = max_project
  end

  def stats_graphs
    @courses_list = public_courses
                    .where(courses_users: { role: CoursesUsers::Roles::INSTRUCTOR_ROLE })
    @courses_presenter = CoursesPresenter.new(current_user: current_user,
                                              courses_list: @courses_list)
  end

  def update_email_preferences
    require_email_preferences_token
    @user_profile.email_opt_out(params[:type])
    flash[:notice] = 'Email Preferences Updated'
    redirect_to '/'
  end

  def delete_profile_image
    @user.user_profile.image.destroy
    @user.user_profile.update_attribute(:image_file_link, nil)
    @user.user_profile.save
    redirect_to controller: 'user_profiles', action: 'show', username: @user.username
  end

  def max_project
    ids_array = public_courses.map(&:home_wiki_id)
    max_ids = ids_array.tally.select { |_k, v| v == ids_array.tally.values.max }.keys
    projects = Wiki.where(id: max_ids).map(&:project)
    return projects.include?('wikipedia') ? 'wikipedia' : projects[0]
  end

  private

  def public_courses
    @user.courses.nonprivate
  end

  def require_write_permissions
    return if current_user == @user
    raise ActionController::InvalidAuthenticityToken, 'Unauthorized'
  end

  def require_email_preferences_token
    return if @user_profile.email_preferences_token == params[:token]
    raise ActionController::InvalidAuthenticityToken, 'Unauthorized'
  end

  def user_profile_params
    params.require(:user_profile).permit(:bio, :image, :location, :institution, :image_file_link)
  end

  def user_email_params
    params.require(:email).permit(:email)
  end

  def set_user
    # Per MediaWiki convention, underscores in username urls represent spaces
    username = CGI.unescape(params[:username]).tr('_', ' ')
    @user = User.find_by(username: username)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_user_profile
    @user_profile = @user.user_profile
    @user_profile = @user.create_user_profile if @user_profile.nil?
  end

  def valid_email?
    return true if user_email_params['email'].blank? # allow deleting email 
    ValidatesEmailFormatOf::validate_email_format(user_email_params['email']).nil?
  end
end
