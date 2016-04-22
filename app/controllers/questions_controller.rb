class QuestionsController < Rapidfire::ApplicationController
  def get_question
    question = Rapidfire::Question.find(params[:id])

    respond_to do |format|
      if !question.nil?
        format.json { render :json => {question: question, question_type: question.class.name.to_s.split("::").last.downcase }}
      else
        format.json { render :json => {message: "Question not found" } }
      end
    end
  end

  def update_position
    question = Rapidfire::Question.find(params[:id])
    question.insert_at(params[:position].to_i)
    render nothing: true
  end

  def results
    respond_to do |format|
      format.csv do
        filename = "#{@survey.name}-results#{Date.today}.csv"
        send_data @survey.to_csv, filename: filename
      end
    end
  end
end
