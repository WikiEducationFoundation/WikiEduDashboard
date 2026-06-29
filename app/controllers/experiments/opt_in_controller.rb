# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/experiments/opt_in_experiment"

module Experiments
  # Handles a student's opt-in/opt-out for an active opt-in research experiment,
  # and reports whether the current student still needs to respond. Opting in
  # triggers the experiment's intervention; a :reauth_required result tells the
  # client to send the student through OAuth re-authorization and retry.
  class OptInController < ApplicationController
    before_action :set_experiment_and_courses_user

    def show
      render json: { experiment_slug: @experiment&.slug,
                     needs_response: needs_response?,
                     userscript_pending: userscript_pending?,
                     copy: @experiment&.student_invitation_copy }
    end

    def opt_in
      return render_not_eligible unless can_respond?

      status = @experiment.handle_student_opt_in(@courses_user)
      render json: { status:, reauth_required: status == :reauth_required }
    end

    def opt_out
      return render_not_eligible unless can_respond?

      @experiment.handle_student_opt_out(@courses_user)
      render json: { status: 'opted_out' }
    end

    private

    def set_experiment_and_courses_user
      @course = Course.find_by(id: params[:course_id])
      @experiment = if params[:experiment_slug]
                      OptInExperiment.find(params[:experiment_slug])
                    elsif @course
                      OptInExperiment.for_course(@course)
                    end
      return unless current_user && @course

      @courses_user = CoursesUsers.find_by(course: @course, user: current_user,
                                           role: CoursesUsers::Roles::STUDENT_ROLE)
    end

    def needs_response?
      return false unless @experiment && @courses_user

      @experiment.needs_response?(@courses_user)
    end

    # True when the student opted in but the userscript install is still pending
    # (e.g. awaiting OAuth re-authorization), so the client should retry it.
    def userscript_pending?
      return false unless @experiment && @courses_user

      record = @experiment.participation(@courses_user)
      !!(record&.opted_in? && record.userscript_installed_at.nil?)
    end

    def can_respond?
      @experiment && @courses_user && @experiment.course_participating?(@course)
    end

    def render_not_eligible
      render json: { status: 'not_eligible' }, status: 422
    end
  end
end
