# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/experiments/opt_in_experiment"

module Experiments
  # Handles a student's opt-in/opt-out for an active opt-in research experiment,
  # reports whether the current student still needs to respond, and describes the
  # remaining userscript install step for a student who has opted in.
  #
  # Opting in makes no edit on the student's behalf. The install step is only
  # cleared once the userscript is confirmed on the student's common.js, which
  # `show` re-checks so the step stops appearing as soon as they have saved it.
  class OptInController < ApplicationController
    before_action :set_experiment_and_courses_user

    def show
      render json: { experiment_slug: @experiment&.slug,
                     needs_response: needs_response?,
                     userscript: userscript_payload,
                     copy: @experiment&.student_invitation_copy }
    end

    def opt_in
      return render_not_eligible unless can_respond?

      @experiment.handle_student_opt_in(@courses_user)
      render json: { status: 'opted_in', userscript: userscript_payload }
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

    # Describes the install step still owed by a student who opted in, or nil
    # when there is nothing left to do. Reading the student's common.js also
    # records the install, so a student who saved the line without telling us
    # stops being prompted.
    def userscript_payload
      record = pending_participation
      return nil unless record

      return nil if CheckExperimentUserscript.new(record, @experiment).status == :installed

      { install_url: @experiment.userscript_install_url(@courses_user.user),
        import_line: @experiment.userscript_import_line }
    end

    def pending_participation
      return nil unless @experiment && @courses_user

      record = @experiment.participation(@courses_user)
      record if record&.opted_in? && record.userscript_installed_at.nil?
    end

    def can_respond?
      @experiment && @courses_user && @experiment.course_participating?(@course)
    end

    def render_not_eligible
      render json: { status: 'not_eligible' }, status: 422
    end
  end
end
