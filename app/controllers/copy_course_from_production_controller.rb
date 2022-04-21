# frozen_string_literal: true

#= Controller for copying course from production to test
class CopyCourseFromProductionController < ApplicationController
  respond_to :html
  before_action :require_admin_permissions

  def index
    @copied = nil
  end

  def copy
    copied = CopyCourseFromProduction.new(params[:url])
    redirect_to copy_course_from_production_path,
                locals: { copied_course: copied.course.slug },
                notice: "Course #{copied.course.title} was created.
                        &nbsp;<a href=\"/courses/#{copied.course.slug}\">Go to course</a>"
  end
end
