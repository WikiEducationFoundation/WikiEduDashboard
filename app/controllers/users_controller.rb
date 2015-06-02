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

  #########################
  # Assignment management #
  #########################
  def assign_params
    params.require(:assignment).permit(:user_id, :article_title)
  end

  def fetch_assign_records
    @course = Course.find_by_slug(params[:course_id])
    @article = Article.find_by(
      title: assign_params['article_title'].gsub(' ', '_'),
      namespace: 0
    )
  end

  def assign
    fetch_assign_records
    title = @article.nil? ? assign_params['article_title'] : @article.title
    Assignment.create(
      user_id: assign_params['user_id'],
      course_id: @course.id,
      article_id: @article.nil? ? nil : @article.id,
      article_title: title.gsub('_', ' ')
    )
    respond_to do |format|
      format.json do
        render json: 'Success!'
      end
    end
  end

  def unassign
    fetch_assign_records
    title = @article.nil? ? assign_params['article_title'] : @article.title
    Assignment.find_by(
      user_id: assign_params['user_id'],
      course_id: @course.id,
      article_id: @article.nil? ? nil : @article.id,
      article_title: title
    ).destroy
    respond_to do |format|
      format.json do
        render json: 'Success!'
      end
    end
  end

  #######################
  # Reviewer management #
  #######################
  def review_params
    params.permit(:assignment_id, :reviewer_id, :reviewer_wiki_id)
  end

  def fetch_review_records
    @course = Course.find_by_slug(params[:course_id])
    if review_params.key? :reviewer_id
      @reviewer = @course.users.find(review_params[:reviewer_id])
    elsif review_params.key? :reviewer_wiki_id
      @reviewer = @course.users.find_by(
        wiki_id: review_params[:reviewer_wiki_id]
      )
    else
      return
    end
  end

  def review
    fetch_review_records
    return if @reviewer.nil?

    AssignmentsUsers.create(
      assignment_id: review_params[:assignment_id],
      user_id: @reviewer.id
    )
    respond_to do |format|
      format.json do
        render json: 'Success!'
      end
    end
  end

  def unreview
    fetch_review_records
    return if @reviewer.nil?

    AssignmentsUsers.find_by(
      assignment_id: review_params[:assignment_id],
      user_id: @reviewer.id
    ).destroy
    respond_to do |format|
      format.json do
        render json: 'Success!'
      end
    end
  end

  #########################
  # Enrollment management #
  #########################
  def enroll_params
    params.permit(:user_id, :user_wiki_id, :role, :old_role)
  end

  def fetch_enroll_records
    if enroll_params.key? :user_id
      @user = User.find(enroll_params[:user_id])
    elsif enroll_params.key? :user_wiki_id
      @user = User.find_by(wiki_id: enroll_params[:user_wiki_id])
    else
      return
    end
  end

  def enroll
    fetch_enroll_records
    return if @user.nil?

    CoursesUsers.create(
      user: @user,
      course_id: params[:course_id],
      role: enroll_params[:role],
      old_role: enroll_params[:old_role]
    )
  end

  def unenroll
    fetch_enroll_records
    return if @user.nil?

    CoursesUsers.find_by(
      user_id: @user.id,
      course_id: params[:course_id],
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
