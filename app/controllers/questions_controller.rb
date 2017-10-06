# frozen_string_literal: true

class QuestionsController < Rapidfire::ApplicationController
  before_action :set_question

  def get_question
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
        send_data @question.to_csv, filename: filename
      end
    end
  end

  private

  def set_question
    @question = Rapidfire::Question.find(params[:id])
  end
end
