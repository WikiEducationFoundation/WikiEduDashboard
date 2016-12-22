# frozen_string_literal: true
#= Controller for campaign/course functionality
class UnsubmittedCoursesController < ApplicationController
  respond_to :html

  def index
    @presenter = CoursesPresenter.new(current_user, 'none')
  end
end
