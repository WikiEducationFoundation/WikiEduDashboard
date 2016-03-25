class SurveyAssignmentsController < ApplicationController
  before_action :set_survey_assignment, only: [:show, :edit, :update, :destroy]
  layout 'surveys'
  # GET /survey_assignments
  # GET /survey_assignments.json
  def index
    @survey_assignments = SurveyAssignment.all
  end

  # GET /survey_assignments/1
  # GET /survey_assignments/1.json
  def show
  end

  # GET /survey_assignments/new
  def new
    @survey_assignment = SurveyAssignment.new
  end

  # GET /survey_assignments/1/edit
  def edit
  end

  # POST /survey_assignments
  # POST /survey_assignments.json
  def create
    @survey_assignment = SurveyAssignment.new(survey_assignment_params)

    respond_to do |format|
      if @survey_assignment.save
        format.html { redirect_to survey_assignments_path, notice: 'Survey assignment was successfully created.' }
        format.json { render :show, status: :created, location: @survey_assignments }
      else
        format.html { render :new }
        format.json { render json: @survey_assignment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /survey_assignments/1
  # PATCH/PUT /survey_assignments/1.json
  def update
    respond_to do |format|
      if @survey_assignment.update(survey_assignment_params)
        format.html { redirect_to survey_assignments_path, notice: 'Survey assignment was successfully updated.' }
        format.json { render :show, status: :ok, location: @survey_assignments }
      else
        format.html { render :edit }
        format.json { render json: @survey_assignment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /survey_assignments/1
  # DELETE /survey_assignments/1.json
  def destroy
    @survey_assignment.destroy
    respond_to do |format|
      format.html { redirect_to survey_assignments_url, notice: 'Survey assignment was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_survey_assignment
      @survey_assignment = SurveyAssignment.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def survey_assignment_params
      params.require(:survey_assignment).permit(:survey_id,:cohort_ids, :send_before, :send_date_relative_to, :send_date_days, :courses_user_role)
    end
end
