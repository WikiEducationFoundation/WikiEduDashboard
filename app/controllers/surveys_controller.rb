class SurveysController < ApplicationController
  helper Rapidfire::ApplicationHelper
  include CourseHelper
  include SurveysHelper
  include QuestionGroupsHelper

  before_action :require_admin_permissions, except: [:show]
  before_action :set_survey, only: [
    :show,
    :edit,
    :update,
    :destroy,
    :edit_question_groups,
    :course_select,
    :show_with_course
  ]
  before_action :ensure_logged_in
  before_action :set_question_groups, only: [
    :show,
    :edit,
    :edit_question_groups,
    :show_with_course
  ]
  before_action :check_if_closed, only: [:show]
  before_action :set_notification, only: [:show]
  before_action :set_course, only: [:show]

  # GET /surveys
  # GET /surveys.json
  def index
    @surveys = Survey.all
  end

  # GET /surveys/1
  # GET /surveys/1.json
  def show
    @courses = Course.all
    unless validate_user_for_survey
      redirect_to(main_app.root_path, flash: { notice: 'Sorry, You do not have access to this survey' })
      return
    end
    if @survey.show_courses && !course?
      render 'course_select'
    else
      render 'show'
    end
  end

  def course_select
    @courses = Course.all
  end

  # GET /surveys/new
  def new
    @survey = Survey.new
  end

  # GET /surveys/1/edit
  def edit
  end

  # GET /surveys/1/question_group
  def edit_question_groups
  end

  # POST /surveys
  # POST /surveys.json
  def create
    @survey = Survey.new(survey_params)

    respond_to do |format|
      if @survey.save
        format.html { redirect_to surveys_path, notice: 'Survey was successfully created.' }
        format.json { render :show, status: :created, location: @survey }
      else
        format.html { render :new }
        format.json { render json: @survey.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /surveys/1
  # PATCH/PUT /surveys/1.json
  def update
    respond_to do |format|
      if @survey.update(survey_params)
        format.html { redirect_to surveys_path, notice: 'Survey was successfully updated.' }
        format.json { render :show, status: :ok, location: @survey }
      else
        format.html { render :edit }
        format.json { render json: @survey.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /surveys/1
  # DELETE /surveys/1.json
  def destroy
    @survey.destroy
    respond_to do |format|
      format.html { redirect_to surveys_url, notice: 'Survey was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def clone
    clone = Survey.find(params[:id]).deep_clone include: [:rapidfire_question_groups]
    clone.name = "#{clone.name} (Copy)"
    clone.save
    redirect_to surveys_path
  end

  def clone_question_group
    clone = Rapidfire::QuestionGroup.find(params[:id]).deep_clone include: [:questions]
    clone.name = "#{clone.name} (Copy)"
    clone.save
    redirect_to rapidfire.question_groups_path
  end

  def clone_question
    clone = Rapidfire::Question.find(params[:id]).deep_clone
    clone.question_text = "(Copy) #{clone.question_text}"
    clone.save
    redirect_to rapidfire.question_group_questions_url(clone.question_group_id)
  end

  def update_question_group_position
    question_group = SurveysQuestionGroup.where(
      survey_id: params[:survey_id],
      rapidfire_question_group_id: params[:question_group_id]).first
    question_group.insert_at(params[:position].to_i)
    render nothing: true
  end

  private

  def set_survey
    @survey = Survey.find(params[:id])
  end

  def set_question_groups
    @question_groups = Rapidfire::QuestionGroup.all
    @surveys_question_groups = SurveysQuestionGroup.by_position(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def survey_params
    params.require(:survey).permit(:name,
                                   :intro,
                                   :thanks,
                                   :show_courses,
                                   :closed,
                                   :open,
                                   rapidfire_question_group_ids: [])
  end

  def validate_user_for_survey
    return true if @survey.open
    return true if can_administer?
    return true if !current_user.nil? && user_is_assigned_to_survey
    return false
  end

  def user_is_assigned_to_survey(return_notification = false)
    users = courses_users
    return false if users.empty?
    users.each do |cu|
      notification = survey_notification(cu.id)
      return false unless notification && notification.survey.id == @survey.id
      return true unless return_notification
      return notification if return_notification
    end
  end

  def ensure_logged_in
    return true if current_user
    render 'login'
  end

  def courses_users
    CoursesUsers.where(user_id: current_user.id)
  end

  def survey_notification(id)
    SurveyNotification.find_by(courses_user_id: id)
  end

  def check_if_closed
    if @survey.closed
      redirect_to(main_app.root_path, flash: { notice: 'Sorry, this survey has been closed.' })
    end
  end

  def set_notification
    @notification = user_is_assigned_to_survey(true)
  end

  def set_course
    @course = find_course_by_slug(params[:course_slug]) if course_slug?
    @course = @notification.course if @notification.instance_of?(SurveyNotification)
  end

  def course_slug?
    params.key?(:course_slug)
  end

  def course?
    !@course.nil?
  end
end
