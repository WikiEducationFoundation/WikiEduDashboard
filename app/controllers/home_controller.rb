#= Controller for home page
class HomeController < ApplicationController
  respond_to :html
  layout 'home'

  def index
    cohort = ENV['default_cohort']
    @presenter = CoursesPresenter.new(current_user, cohort)
  end

end
