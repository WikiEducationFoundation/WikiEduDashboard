#= Controller for week functionality
class WeeksController < ApplicationController
  def new
    @course = Course.find_by_slug(params[:id])
  end
end
