# frozen_string_literal: true

#= Controller for Copy Course tool
class CopyCourseController < ApplicationController
  respond_to :html
  before_action :require_admin_if_wiki_ed
  def index; end

  def copy
    service = CopyCourse.new(url: params[:url], user_data: params[:user_data])
    response = service.make_copy
    if response[:error].present?
      redirect_to(copy_course_path,
                  flash: { error: "Course not created: #{response[:error]}" })
    else
      course = response[:course]
      course.update(
        flags: { timeline_enabled: true },
        cloned_status: 3,
        expected_students: course.expected_students || 0,
        term: ''
      )
      redirect_to "/courses/#{course.slug}"
    end
  end

  def require_admin_if_wiki_ed
    require_admin_permissions if Features.wiki_ed?
  end
end
