# frozen_string_literal: true

# Controller for data on which trainings a user has completed
class TrainingStatusController < ApplicationController
  def show
    @course = Course.find(params[:course_id])
    @assigned_training_modules = @course.training_modules
    @user = User.find(params[:user_id])
  end
end
