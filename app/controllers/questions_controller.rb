class QuestionsController < Rapidfire::ApplicationController
  before_action :set_question

  def get_question
    respond_to do |format|
      if !@question.nil?
        format.json { render :json => {question: @question, question_type: @question.class.name.to_s.split("::").last.downcase }}
      else
        format.json { render :json => {message: "Question not found" } }
      end
    end
  end

  def update_position
    @question.insert_at(params[:position].to_i)
    render nothing: true
  end

  def results
    respond_to do |format|
      format.csv do
        filename = "Question##{@question.id}-results#{Date.today}.csv"
        send_data @question.to_csv, filename: filename
      end
    end
  end

  private

  def set_question
    @question = Rapidfire::Question.find(params[:id])
  end
end
