# frozen_string_literal: true

class QuestionsController < Rapidfire::ApplicationController
  before_action :require_admin_permissions
  before_action :set_question
  before_action :protect_confidentiality, only: [:results]

  def question
    render json: { question: @question,
                   question_type: @question.class.name.to_s.split('::').last.downcase }
  end

  def update_position
    @question.insert_at(params[:position].to_i)
    head :ok
  end

  def results
    respond_to do |format|
      format.csv do
        filename = "Question##{@question.id}-results#{Time.zone.today}.csv"
        send_data @question.to_csv, filename:
      end
    end
  end

  private

  def set_question
    @question = Rapidfire::Question.find(params[:id])
  end

  # Answers aren't separated by survey, so a question group that is part of
  # any confidential survey has confidential results.
  def protect_confidentiality
    return unless @question.question_group.surveys.exists?(confidential_results: true)
    return if current_user.super_admin?
    render plain: 'The results for this survey are confidential.',
           status: :forbidden
  end
end
