# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/training_module"

# Controller for data on which trainings a user has completed
class TrainingStatusController < ApplicationController
  def show
    @course = Course.find(params[:course_id])
    @assigned_training_modules = @course.training_modules
    @user = User.find(params[:user_id])
  end

  def user
    @user = User.find_by(username: params[:username])
  end
end
