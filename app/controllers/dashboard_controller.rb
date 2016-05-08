#= Controller for dashboard functionality
class DashboardController < ApplicationController
  respond_to :html

  def index
    unless current_user
      redirect_to root_path
      return
    end

    set_admin_courses_if_admin

    @pres = DashboardPresenter.new(current_courses, past_courses,
                                   @submitted, @strictly_current, current_user)
  end

  private

  def set_admin_courses_if_admin
    @submitted = []
    @strictly_current = []

    return unless current_user.admin?
    @submitted = Course.submitted_listed
    @strictly_current = current_user.courses.strictly_current
  end

  def current_courses
    current_user.courses.current_and_future.listed
  end

  def past_courses
    current_user.courses.archived.listed
  end
end
