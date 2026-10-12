# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/experiments/opt_in_experiment"
require_dependency "#{Rails.root}/lib/importers/user_importer"

module Experiments
  # Admin page for opting a student out of one opt-in experiment by username,
  # for students who ask staff to withdraw them. The admin looks the student up
  # first and opts them out from the results, so the action is only taken after
  # seeing whose courses it affects. Records for other experiments are left
  # alone; see OptInExperiment#opt_out_student.
  class StudentOptOutController < ApplicationController
    before_action :require_admin_permissions
    before_action :set_experiment

    def show
      return if params[:username].blank?

      @user = find_user
      return unless @user
      @participations = @experiment.student_participations(@user)
      @opt_out_pending = @participations.values.any? { |record| !record&.opted_out? }
    end

    def opt_out
      user = find_user
      if user
        @experiment.opt_out_student(user)
        flash[:notice] = 'The student has been opted out of this experiment.'
      else
        flash[:error] = t('update_username.not_found')
      end
      redirect_to student_opt_out_path(username: user&.username)
    end

    private

    # Opt-in experiments only run on the Wiki Education Dashboard.
    def set_experiment
      @experiment = OptInExperiment.find(params[:experiment_slug]) if Features.wiki_ed?
      raise ActionController::RoutingError, 'Not Found' unless @experiment
    end

    def find_user
      return if params[:username].blank?
      User.find_by(username: UserImporter.sanitize_username(params[:username]))
    end

    def student_opt_out_path(username:)
      path = "/experiments/#{@experiment.slug}/student_opt_out"
      username ? "#{path}?#{{ username: }.to_query}" : path
    end
  end
end
