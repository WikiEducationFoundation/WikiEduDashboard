# frozen_string_literal: true

#= Controller for Copy Course tool
class CopyCourseController < ApplicationController
  respond_to :html
  before_action :require_admin_permissions
  def index; end

  def copy
    service = CopyCourse.new(url: params[:url])
    response = service.make_copy
    if response[:error].present?
      redirect_to(copy_course_path,
                  flash: { error: "Course not created: #{response[:error]}" })
    else
      course = response[:course]
      redirect_to copy_course_path,
                  notice: "Course #{course.title} was created."\
                          "&nbsp;<a href=\"/courses/#{course.slug}\">Go to course</a>"
    end
  end
end
