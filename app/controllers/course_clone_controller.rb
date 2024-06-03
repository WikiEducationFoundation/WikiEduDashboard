# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/course_clone_manager"

class CourseCloneController < ApplicationController
  before_action :require_signed_in

  def clone
    @course = Course.find(params[:id])
    check_permission

    campaign_slug = clone_params[:campaign_slug]
    clone_assignments = clone_params[:copy_assignments]
    new_course = CourseCloneManager.new(course: @course, user: current_user, clone_assignments:,
                                        campaign_slug:).clone!

    respond_to do |format|
      format.json { render json: { course: new_course.as_json } }
      format.html { redirect_to "/courses/#{new_course.slug}" }
    end
  end

  private

  def check_permission
    return unless Features.wiki_ed? # On P&E Dashboard, anyone may clone a course
    return if current_user.can_edit?(@course) # Otherwise, only instructors or admins can clone
    exception = ActionController::InvalidAuthenticityToken.new('Unauthorized')
    raise exception
  end

  def clone_params
    params.permit(:campaign_slug, :copy_assignments)
  end
end
