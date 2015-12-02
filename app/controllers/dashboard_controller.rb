#= Controller for course functionality
class DashboardController < ApplicationController
  respond_to :html

  def index
    @courses = current_user.courses.current_and_future.listed
    @current = @courses.select { |c| c.end >= Time.now }
    @past = @courses.select { |c| c.end < Time.now }
    @submitted = []

    if user_signed_in? && current_user.admin?
      @submitted = Course.submitted_listed
    end
  end
end
