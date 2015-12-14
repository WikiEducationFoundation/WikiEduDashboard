#= Controller for dashboard functionality
class DashboardController < ApplicationController
  respond_to :html

  def index
    current = current_user.courses.current_and_future.listed
    past = current_user.courses.archived.listed
    submitted = []
    strictly_current = []

    if current_user.admin?
      submitted = Course.submitted_listed
      strictly_current = current_user.courses.strictly_current
    end

    @pres = DashboardPresenter.new(current, past, submitted, strictly_current, current_user)
  end
end
