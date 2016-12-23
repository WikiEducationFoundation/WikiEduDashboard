# frozen_string_literal: true
class UnsubmittedCoursesController < ApplicationController
  respond_to :html

  def index
    @presenter = CoursesPresenter.new(current_user, 'none')
  end
end
