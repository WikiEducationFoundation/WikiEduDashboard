# frozen_string_literal: true

# Controller for data on which trainings a user has completed
class TrainingStatusController < ApplicationController
  def show
    @course = Course.find(params[:course_id])
    @assigned_training_modules = @course.training_modules
    @user = User.find(params[:user_id])
  end

  def user
    @user = User.find_by(username: params[:username])
    training_module_ids = @user.training_modules_users.pluck(:training_module_id)
    @training_modules = TrainingModule.all.select { |tm| training_module_ids.include?(tm.id) }
  end
end
