require "#{Rails.root}/lib/wiki_edits"

#= Controller for user functionality
class UsersController < ApplicationController
  respond_to :html, :json

  def signout
    current_user.update_attributes(wiki_token: nil, wiki_secret: nil)
    redirect_to true_destroy_user_session_path
  end

  def user_params
    params.permit(
      users: [:id, :wiki_id, :deleted],
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
    user_params['users'].each do |student|
      if student['deleted']
        s_assignments = @course.assignments.select do |a|
          a.user_id == student['id']
        end
        s_assignments.to_json!
        WikiEdits.update_assignments current_user, @course, s_assignments, true
      end
      update_util User, student
    end

    WikiEdits.update_assignments current_user, @course,
                                 user_params['assignments']

    user_params['assignments'].each do |assignment|
      assignment['course_id'] = @course.id
      assignment['article_title'].gsub!(' ', '_')
      assigned = Article.find_by(title: assignment['article_title'])
      assignment['article_id'] = assigned.id unless assigned.nil?
      update_util Assignment, assignment
    end

    WikiEdits.update_course(@course, current_user)
    render 'users'
  end

  #########################
  # Enrollment management #
  #########################
  def enroll
    if request.get?
      enroll_user
    elsif request.post?
      add
    elsif request.delete?
      remove
    end
  end

  def enroll_user
    # Redirect to sign in (with callback leading back to this method)
    @course = Course.find_by_slug(params[:course_id])
    if current_user.nil?
      auth_path = user_omniauth_authorize_path(:mediawiki)
      path = "#{auth_path}?origin=#{request.original_url}"
      redirect_to path
      return
    end

    # Make sure the user isn't already enrolled.
    if CoursesUsers.where(user_id: current_user.id,
                          course_id: @course.id,
                          role: 0).empty?
      redirect_to course_slug_path(@course.slug)
      return
    end

    # Check passcode, enroll if valid
    if !@course.passcode.nil? && params[:passcode] == @course.passcode
      CoursesUsers.create(
        user_id: current_user.id,
        course_id: @course.id,
        role: 0
      )
      WikiEdits.enroll_in_course(@course, current_user)
      WikiEdits.update_course(@course, current_user)
    end
    # Redirect to course
    redirect_to course_slug_path(@course.slug)
  end

  def enroll_params
    params.require(:user).permit(:user_id, :wiki_id, :role)
  end

  def fetch_enroll_records
    @course = Course.find_by_slug(params[:id])
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
    if !@user.nil?
      CoursesUsers.create(
        user: @user,
        course_id: @course.id,
        role: enroll_params[:role]
      )

      WikiEdits.update_course(@course, current_user)
      render 'users'
    else
      username = enroll_params[:user_id] || enroll_params[:wiki_id]
      render json: { message: "Sorry, #{username} is not an existing user." }, status: 404
    end
  end

  def remove
    fetch_enroll_records
    return if @user.nil?

    cu = CoursesUsers.find_by(
      user_id: @user.id,
      course_id: @course.id,
      role: enroll_params[:role]
    )
    WikiEdits.update_assignments current_user, @course,
                                 cu.assignments.as_json, true
    cu.destroy

    render 'users'
    WikiEdits.update_course(@course, current_user)
  end

  def set_role
    fetch_enroll_records
    return if @user.nil? || @course.nil?

    CoursesUsers.find_by(
      user_id: @user.id,
      course_id: params[:course_id],
      role: enroll_params[:old_role]
    ).update(role: enroll_params[:role])

    WikiEdits.update_course(@course, current_user)
  end
end
