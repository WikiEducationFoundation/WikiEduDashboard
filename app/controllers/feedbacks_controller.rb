class FeedbacksController < ApplicationController
  def create
  	feedback = Feedback.new(form_params)
  	feedback.save
  	respond_to do |format|
  		resp = { :id => feedback.id }
  		format.json { render :json => resp }
  	end
  end

  def form_params
  	params.require(:feedback).permit(:text, :assignment_id)
  end

  def destroy
  	Feedback.delete(params[:id])
  end
end
