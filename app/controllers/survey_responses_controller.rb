# frozen_string_literal: true

class SurveyResponsesController < ApplicationController
  before_action :require_admin_permissions
  layout 'surveys'

  def index
    @responses = []
    Rapidfire::AnswerGroup.order(created_at: :desc).first(100).each do |answer_group|
      @responses << { user: User.find(answer_group.user_id),
                      answer_group:,
                      question_group: answer_group.question_group }
    end
  end

  def delete
    @answer_group = Rapidfire::AnswerGroup.find(params[:id])
    @answer_group.answers.destroy_all
    @answer_group.destroy
    redirect_to '/survey/responses'
  end
end
