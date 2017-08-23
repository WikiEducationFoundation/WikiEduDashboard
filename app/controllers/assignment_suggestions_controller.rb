# frozen_string_literal: true

class AssignmentSuggestionsController < ApplicationController
  before_action :require_signed_in

  def create
    suggestion = AssignmentSuggestion.new(form_params)
    suggestion.save
    respond_to do |format|
      resp = { id: suggestion.id }
      format.json { render json: resp }
    end
  end

  def destroy
    suggestion = AssignmentSuggestion.find(params[:id])
    verify_deletion_permission(suggestion)
    suggestion.destroy!
    head :ok
  end

  private

  def form_params
    params.require(:feedback).permit(:text, :assignment_id, :user_id)
  end

  def verify_deletion_permission(suggestion)
    return if current_user.admin?
    return if suggestion.user_id == current_user.id
    exception = ActionController::InvalidAuthenticityToken.new('Unauthorized')
    raise exception
  end
end
