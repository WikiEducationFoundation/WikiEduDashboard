# frozen_string_literal: true

class SurveyResponsesController < ApplicationController
  before_action :require_admin_permissions
  layout 'surveys'

  def index
    answer_groups = Rapidfire::AnswerGroup.includes(:question_group, :user)
                                          .order(created_at: :desc)
                                          .limit(100)

    @responses = answer_groups.map do |answer_group|
      { user: answer_group.user, question_group: answer_group.question_group, answer_group: }
    end
  end

  def delete
    @answer_group = Rapidfire::AnswerGroup.find(params[:id])
    @answer_group.answers.destroy_all
    @answer_group.destroy
    redirect_to '/survey/responses'
  end
end
