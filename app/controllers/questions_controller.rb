class QuestionsController < Rapidfire::ApplicationController
  def get_question
    question = Rapidfire::Question.find(params[:id])
    respond_to do |format|
      if !question.nil?
        format.json { render :json => {question: question }}
      else
        format.json { render :json => {message: "Question not found" } }
      end
    end
  end

  def add_conditional
    binding.pry
  end
end
