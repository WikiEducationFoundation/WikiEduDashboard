# frozen_string_literal: true

# Controller for data on which trainings a user has completed
class TrainingStatusController < ApplicationController
  def show
    @course = Course.find(params[:course_id])
    @user = User.find(params[:user_id])
    render json: {} and return unless can_see_training_status?

    @assigned_training_modules = @course.training_modules
  end

  def user
    @user = User.find_by(username: params[:username])
  end

  private

  def can_see_training_status?
    return true if current_user&.can_edit?(@course)
    return true if current_user&.id == @user.id

    false
  end
end
