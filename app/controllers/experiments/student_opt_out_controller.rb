# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/experiments/opt_in_experiment"
require_dependency "#{Rails.root}/lib/importers/user_importer"

module Experiments
  # Admin page for opting a student out of one opt-in experiment by username,
  # for students who ask staff to withdraw them. Records for other experiments
  # are left alone; see OptInExperiment#opt_out_student.
  class StudentOptOutController < ApplicationController
    before_action :require_admin_permissions
    before_action :set_experiment

    def show
      return if params[:username].blank?

      @user = find_user
      @participations = @experiment.student_participations(@user) if @user
    end

    def opt_out
      user = find_user
      if user
        @experiment.opt_out_student(user)
      else
        flash[:error] = t('update_username.not_found')
      end
      redirect_to student_opt_out_path(username: user&.username)
    end

    private

    def set_experiment
      @experiment = OptInExperiment.find(params[:experiment_slug])
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
