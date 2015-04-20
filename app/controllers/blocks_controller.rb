#= Controller for block functionality
class BlocksController < ApplicationController
  def new
    @course = Course.find_by_slug(params[:id])
  end
end
