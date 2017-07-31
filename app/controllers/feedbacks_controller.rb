class FeedbacksController < ApplicationController
  def create
  	Feedback.new(form_params).save
  end

  def form_params
  	params.require(:feedback).permit(:text, :assignment_id)
  end
end
