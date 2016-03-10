class SurveysController < ApplicationController
  helper Rapidfire::ApplicationHelper

  before_action :set_survey, only: [:show, :edit, :update, :destroy, :edit_question_groups]
  before_action :set_question_groups, only: [:show, :edit, :edit_question_groups]

  # GET /surveys
  # GET /surveys.json
  def index
    @surveys = Survey.all
  end

  # GET /surveys/1
  # GET /surveys/1.json
  def show
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
    question_group = SurveysQuestionGroup.where(survey_id: params[:survey_id], rapidfire_question_group_id: params[:question_group_id]).first
    question_group.insert_at(params[:position].to_i)
    render nothing: true
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_survey
      @survey = Survey.find(params[:id])
    end

    def set_question_groups
      @question_groups = Rapidfire::QuestionGroup.all
      @surveys_question_groups = SurveysQuestionGroup.by_position(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def survey_params
      # binding.pry
      params.require(:survey).permit(:name, :rapidfire_question_group_ids => [])
    end
end
