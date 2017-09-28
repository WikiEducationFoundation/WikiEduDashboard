# frozen_string_literal: true

require "#{Rails.root}/lib/course_clone_manager"

class CourseCloneController < ApplicationController
  before_action :require_signed_in

  def clone
    @course = Course.find(params[:id])
    check_permission
    new_course = CourseCloneManager.new(@course, current_user).clone!
    render json: { course: new_course.as_json }
  end

  private

  def check_permission
    return if current_user.can_edit?(@course)
    exception = ActionController::InvalidAuthenticityToken.new('Unauthorized')
    raise exception
  end
end
