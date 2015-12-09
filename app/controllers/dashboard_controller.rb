#= Controller for dashboard functionality
class DashboardController < ApplicationController
  respond_to :html

  def index
    binding.pry

    current = current_user.courses.current_and_future.listed
    past = current_user.courses.archived.listed
    submitted = []

    if current_user.admin?
      submitted = Course.submitted_listed
    end

    @pres = DashboardPresenter.new(current, past, submitted, current_user)
  end
end
