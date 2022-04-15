# frozen_string_literal: true

#= Controller for copying course from production to test
class CopyCourseFromProductionController < ApplicationController
  respond_to :html
  before_action :require_admin_permissions

  def index
    @copied_course = nil
  end

  def copy
    copied_course = CopyCourseFromProduction.new(params[:url])
    pp "http://localhost:3000/courses/#{copied_course.course_slug}"
    redirect_to copy_course_from_production_path,
                locals: { copied_course: copied_course.course_slug },
                notice: "Course #{copied_course.title} was created. http://localhost:3000/courses/#{copied_course.course_slug}"
  end
end
