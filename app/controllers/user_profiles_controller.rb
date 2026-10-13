# frozen_string_literal: true

class UserProfilesController < ApplicationController
  include UserProfileAnalytics
  respond_to :html, :json

  before_action :set_user
  before_action :set_user_profile, only: [:update, :update_email_preferences]
  before_action :require_write_permissions, only: [:update]

  def taught_courses_articles
    user = User.find_by(username: params[:username])
    return render json: { error: 'User not found' }, status: :not_found if user.nil?

    data = user.taught_courses_with_edited_articles

    render json: data, status: :ok
  end

  def user_articles
    return render json: { error: 'User not found' }, status: :not_found unless @user

    begin
      @user_articles = ArticlesCourses
                        .where('user_ids LIKE ?', "%- #{@user.id}\n%")
                        .joins(:article, :course)
                        .where(courses: { private: false })
                        .where(articles: { deleted: false, namespace: Article::Namespaces::MAINSPACE })
                        .includes(:article, :course)
                        .includes(article: :wiki)
                        .order(character_sum: :desc)

      @course_id = params[:course_id]
      @user_articles = @user_articles.where(course_id: @course_id) if @course_id.present?

      @user_revisions = {}
    rescue StandardError => e
      render json: { error: e.message, backtrace: e.backtrace.first(5) }, status: :internal_server_error
    end
  end

  def show
    if @user
      @last_courses_user = @user.courses_users.includes(:course)
                                .where(courses: { private: false }).last
      @user_profile = @user.user_profile || UserProfile.new(user_id: @user.id)
    else
      flash[:notice] = 'User not found'
      redirect_to controller: 'dashboard', action: 'index'
    end
  end

  def update
    if params[:user_profile][:image].present? || params[:user_profile][:image_file_link].present?
      @user_profile.image.destroy
      @user_profile.image_file_link = nil
    end
    validate_update
  end

  def validate_update
    email_must_be_present_for_instructors
    if @user.errors.empty? &&
       @user_profile.update(user_profile_params) && @user.update(user_email_params)
      flash[:notice] = 'Profile Updated'
    else
      flash[:error] = (@user.errors.full_messages + @user_profile.errors.full_messages).join(', ')
    end
  rescue Paperclip::Errors::CommandNotFoundError
    flash[:error] = 'Unable to process uploaded image because ImageMagick is not installed.'
  ensure
    user_profile_redirect
  end

  def stats
    return render json: { error: 'User not found' }, status: :not_found unless @user
    @courses_users = @user.courses_users.includes(:course).where(courses: { private: false })
    @individual_stats_presenter = IndividualStatisticsTimeslicePresenter.new(user: @user)
    @courses_list = public_courses
                    .where(courses_users: { role: CoursesUsers::Roles::INSTRUCTOR_ROLE })
    @courses_presenter = CoursesPresenter.new(current_user:,
                                              courses_list: @courses_list)
    @user_uploads = CommonsUpload.where(user_id: @user.id).order(uploaded_at: :desc).first(20)
    @max_project = max_project
    
    # Get articles by language/project for stats
    @articles_by_language = get_articles_by_language
  end

  def stats_graphs
    @courses_list = public_courses
                    .where(courses_users: { role: CoursesUsers::Roles::INSTRUCTOR_ROLE })
    @courses_presenter = CoursesPresenter.new(current_user:,
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
    @user.user_profile.update(image_file_link: nil)
    @user.user_profile.save
    redirect_to controller: 'user_profiles', action: 'show', username: @user.username
  end

  private
end