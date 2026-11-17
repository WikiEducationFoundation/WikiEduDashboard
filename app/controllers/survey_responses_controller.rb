# frozen_string_literal: true

class SurveyResponsesController < ApplicationController
  before_action :require_admin_permissions
  layout 'surveys'

  def index
    answer_groups = survey_answer_groups.includes(:question_group, :user)
                                        .order(created_at: :desc)
    unless current_user.super_admin?
      answer_groups = answer_groups.where.not(question_group_id: confidential_question_group_ids)
    end
    answer_groups = answer_groups.limit(100)

    @responses = answer_groups.map do |answer_group|
      { user: answer_group.user, question_group: answer_group.question_group, answer_group: }
    end
  end

  def delete
    @answer_group = survey_answer_groups.find(params[:id])
    @answer_group.answers.destroy_all
    @answer_group.destroy
    redirect_to '/survey/responses'
  end

  private

  # Answers to Scholars & Scientists applications are Rapidfire answer groups
  # too, but they belong to the application review pages, which delete them
  # along with the application.
  def survey_answer_groups
    Rapidfire::AnswerGroup.where(course_application_id: nil)
  end

  # Who answered a confidential survey is confidential too, as its results
  # are (see protect_confidentiality in SurveysController).
  def confidential_question_group_ids
    # NOT IN with a NULL in the list matches nothing, which would hide every response.
    SurveysQuestionGroup.joins(:survey).where(surveys: { confidential_results: true })
                        .where.not(rapidfire_question_group_id: nil)
                        .select(:rapidfire_question_group_id)
  end
end
