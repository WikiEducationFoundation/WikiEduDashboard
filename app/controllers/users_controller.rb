#= Controller for user functionality
class UsersController < ApplicationController
  respond_to :html, :json

  # Support the user revision dropdown
  def revisions
    @revisions = Course.find(params[:course_id]).revisions
                 .where(user_id: params[:user_id]).order(date: :desc)
                 .limit(params[:limit].nil? ? 100 : params[:limit])
                 .drop(params[:drop].to_i || 0)
    revisions = { revisions: @revisions }
    r_list = render_to_string partial: 'revisions/list', locals: revisions
    r_list =  r_list.html_safe.gsub(/\n/, '').gsub(/\t/, '').gsub(/\r/, '')
    render json: { html: r_list, error: '' }
  end

  def signout
    current_user.update_attributes(wiki_token: nil, wiki_secret: nil)
    redirect_to true_destroy_user_session_path
  end

  def user_params
    params.permit(
      students: [:id, :wiki_id, :deleted],
      assignments: [:id, :user_id, :article_title, :role, :course_id, :deleted]
    )
  end

  def update_util(model, object)
    if object['id'].nil?
      model.create object
    elsif object['deleted']
      model.destroy object['id']
    else
      model.update object['id'], object
    end
  end

  def save
    @course = Course.find_by_slug(params[:course_id])
    user_params['students'].each do |student|
      update_util User, student
    end
    user_params['assignments'].each do |assignment|
      assignment['course_id'] = @course.id
      update_util Assignment, assignment
    end
  end

  #########################
  # Enrollment management #
  #########################
  def enroll
    # Redirect to sign in (with callback leading back to this method)
    @course = Course.find_by_slug(params[:course_id])
    if current_user.nil?
      auth_path = user_omniauth_authorize_path(:mediawiki)
      path = "#{auth_path}?origin=#{request.original_url}"
      redirect_to path
      return
    end

    # Check passcode, enroll if valid
    if @course.passcode? && params[:passcode] == @course.passcode
      CoursesUsers.create(
        user_id: current_user.id,
        course_id: @course.id,
        role: 0
      )
    end

    # Redirect to course
    redirect_to course_slug_path(@course.slug)
  end

  def enroll_params
    params.require(:student).permit(:user_id, :wiki_id, :role)
  end

  def fetch_enroll_records
    @course = Course.find_by_slug(params[:course_id])
    if enroll_params.key? :user_id
      @user = User.find(enroll_params[:user_id])
    elsif enroll_params.key? :wiki_id
      @user = User.find_by(wiki_id: enroll_params[:wiki_id])
    else
      return
    end
  end

  def add
    fetch_enroll_records
    return if @user.nil?

    CoursesUsers.create(
      user: @user,
      course_id: @course.id,
      role: enroll_params[:role]
    )
  end

  def remove
    fetch_enroll_records
    return if @user.nil?

    CoursesUsers.find_by(
      user_id: @user.id,
      course_id: @course.id,
      role: enroll_params[:role]
    ).destroy
  end

  def set_role
    fetch_enroll_records
    return if @user.nil?

    CoursesUsers.find_by(
      user_id: @user.id,
      course_id: params[:course_id],
      role: enroll_params[:old_role]
    ).update(role: enroll_params[:role])
  end
end
