# frozen_string_literal: true
class SurveysController < ApplicationController
  layout 'surveys_minimal', only: [:show]
  layout 'application', only: [:optout]

  helper Rapidfire::ApplicationHelper
  include CourseHelper
  include SurveysHelper
  include QuestionGroupsHelper

  before_action :require_admin_permissions, except: [:show]
  before_action :set_survey, only: [
    :show,
    :optout,
    :edit,
    :update,
    :destroy,
    :edit_question_groups,
    :course_select,
    :results
  ]
  before_action :ensure_logged_in
  before_action :set_question_groups, only: [
    :show,
    :edit,
    :edit_question_groups,
    :results
  ]
  before_action :check_if_closed, only: [:show]
  before_action :set_notification, only: [:show]
  before_action :set_course_for_survey, only: [:show]

  # GET /surveys
  # GET /surveys.json
  def index
    @surveys = Survey.all
  end

  def results_index
    @surveys = Survey.all
  end

  def results
    protect_confidentiality { return }
    respond_to do |format|
      format.html
      format.csv do
        filename = "#{@survey.name}-results#{Time.zone.today}.csv"
        send_data @survey.to_csv, filename: filename
      end
    end
  end

  # GET /surveys/1
  # GET /surveys/1.json
  def show
    @courses = Course.all
    unless validate_user_for_survey
      redirect_to(main_app.root_path,
                  flash: { notice: 'Sorry, You do not have access to this survey' })
      return
    end
    # The surveys are highly inaccessible via screen reader.
    # Disabling the javascript and css bypasses many of the UI features of
    # the surveys and puts all questions on display at once, but it is gets
    # around the accessibility probems.
    @accessibility_mode = true if params['accessibility'] == 'true'
    render 'show'
  end

  def optout
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
    raise FailedSaveError unless @survey.save
    respond_to do |format|
      format.html { redirect_to surveys_path, notice: 'Survey was successfully created.' }
      format.json { render :show, status: :created, location: @survey }
    end
  end

  # PATCH/PUT /surveys/1
  # PATCH/PUT /surveys/1.json
  def update
    raise FailedSaveError unless @survey.update(survey_params)
    respond_to do |format|
      format.html { redirect_to surveys_path, notice: 'Survey was successfully updated.' }
      format.json { render :show, status: :ok, location: @survey }
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
    question_group = SurveysQuestionGroup.find_by!(
      survey_id: params[:survey_id],
      rapidfire_question_group_id: params[:question_group_id]
    )
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
                                   :optout,
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
    notifications = current_user.survey_notifications.collect do |n|
      n if n.survey.id == @survey.id
    end
    return false if notifications.empty?
    return true unless return_notification
    return notifications.first
  end

  def ensure_logged_in
    return true if current_user
    render 'login'
  end

  def check_if_closed
    return unless @survey.closed
    redirect_to(main_app.root_path, flash: { notice: 'Sorry, this survey has been closed.' })
  end

  def set_notification
    @notification = user_is_assigned_to_survey(true)
  end

  def set_course
    @course = find_course_by_slug(params[:course_slug]) if course_slug?
    return unless @course.nil?
    @course = @notification.course if @notification.instance_of?(SurveyNotification)
  end

  def course_slug?
    params.key?(:course_slug)
  end

  # Prevents access to survey results if they are set to be confidential
  def protect_confidentiality
    return unless @survey.confidential_results
    render plain: 'The results for this survey are confidential.',
           status: 403
    yield
  end

  class FailedSaveError < StandardError; end
end
