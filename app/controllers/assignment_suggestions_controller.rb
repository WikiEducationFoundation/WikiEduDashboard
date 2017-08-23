class AssignmentSuggestionsController < ApplicationController
  def create
  	suggestion = AssignmentSuggestion.new(form_params)
  	suggestion.save
  	respond_to do |format|
  		resp = { :id => suggestion.id }
  		format.json { render :json => resp }
  	end
  end

  def form_params
  	params.require(:feedback).permit(:text, :assignment_id, :user_id)
  end

  def destroy
  	AssignmentSuggestion.delete(params[:id])
  end
end
