# frozen_string_literal: true

# Shows a signed-in student the claim-verification exercise for a course: the
# single pooled claim they have been assigned, its cited source (link out), and
# a handoff to do the verification in their Wikipedia sandbox. The student
# records their findings on-wiki; nothing they produce is stored here.
class ClaimVerificationExercisesController < ApplicationController
  before_action :require_signed_in

  def show
    @course = Course.find_by(slug: params[:id])
    raise ActionController::RoutingError, 'Course not found' if @course.nil?

    @assignment = AssignVerificationClaim.new(user: current_user, course: @course).assignment
    @claim = @assignment&.verification_claim
  end
end
