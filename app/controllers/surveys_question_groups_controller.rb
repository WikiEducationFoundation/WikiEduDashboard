class SurveysQuestionGroupsController < ApplicationController
  before_action :require_admin_permissions
  def update
    respond_to do |format|
      group = SurveysQuestionGroup.find(params[:id])
      if group.update_attribute('show_title', params[:value])
        format.json { render json: { surveys_question_group: group, success: true } }
      else
        format.json { render json: group.errors, status: :unprocessable_entity }
      end
    end
  end
end
