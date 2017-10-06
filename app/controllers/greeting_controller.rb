# frozen_string_literal: true

require "#{Rails.root}/app/workers/greet_students_worker"

class GreetingController < ApplicationController
  respond_to :json
  before_action :require_admin_permissions

  def greet_course_students
    course = Course.find(params[:course_id])
    GreetStudentsWorker.schedule_greetings(course, current_user)
    render json: { success: true }
  end
end
