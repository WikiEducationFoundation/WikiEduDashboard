# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/experiments/opt_in_experiment"

module Experiments
  # Standalone opt-in page for instructors invited by email, mirroring the
  # assignment wizard's research-study panel for courses that never went
  # through the wizard. The signed-in instructor's choice applies to all their
  # eligible courses at once; see OptInExperiment#handle_instructor_opt_in.
  #
  # A signed-out visitor following the emailed link gets the sign-in prompt,
  # and the NotSignedInError rescue stores the return path, so they land back
  # here after logging in.
  class InstructorOptInController < ApplicationController
    before_action :require_signed_in
    before_action :set_experiment

    def show
      @copy = @experiment.instructor_invitation_copy
      @courses = @experiment.eligible_instructed_courses(current_user)
      @choices = @courses.index_with { |course| @experiment.course_choice(course) }
    end

    def opt_in
      @experiment.handle_instructor_opt_in(current_user)
      redirect_with_notice(:opted_in_flash)
    end

    def opt_out
      @experiment.handle_instructor_opt_out(current_user)
      redirect_with_notice(:opted_out_flash)
    end

    private

    def set_experiment
      @experiment = OptInExperiment.find(params[:experiment_slug])
      raise ActionController::RoutingError, 'Not Found' unless @experiment
    end

    def redirect_with_notice(copy_key)
      # No confirmation when there was nothing to apply the choice to; the page
      # will show its no-eligible-courses message instead.
      if @experiment.eligible_instructed_courses(current_user).any?
        flash[:notice] = @experiment.instructor_invitation_copy[copy_key]
      end
      redirect_to "/experiments/#{@experiment.slug}/instructor_optin"
    end
  end
end
