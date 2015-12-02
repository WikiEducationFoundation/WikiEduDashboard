#= Controller for course functionality
class ExploreController < ApplicationController
  respond_to :html

  def index
    cohort = params[:cohort] || ENV['default_cohort']
    @presenter = CoursesPresenter.new(current_user, cohort)
    fail ActionController::RoutingError
      .new('Not Found'), 'Cohort does not exist' unless @presenter.cohort
  end
end
