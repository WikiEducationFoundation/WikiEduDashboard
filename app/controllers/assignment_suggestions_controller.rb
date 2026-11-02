# frozen_string_literal: true

class AssignmentSuggestionsController < ApplicationController
  before_action :require_signed_in

  def create
    assignment = Assignment.find(form_params[:assignment_id])
    verify_creation_permission(assignment)
    suggestion = AssignmentSuggestion.new(text: form_params[:text], assignment:,
                                          user: current_user)
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

  # Suggestions come from people in the course: classmates, reviewers,
  # instructors and staff. The author is always the signed-in user.
  def verify_creation_permission(assignment)
    course = assignment.course
    return if current_user.nonvisitor?(course) || current_user.can_edit?(course)
    raise ActionController::InvalidAuthenticityToken, 'Unauthorized'
  end

  def verify_deletion_permission(suggestion)
    return if current_user.admin?
    return if suggestion.user_id == current_user.id
    exception = ActionController::InvalidAuthenticityToken.new('Unauthorized')
    raise exception
  end
end
