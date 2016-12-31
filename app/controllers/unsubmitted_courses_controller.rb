# frozen_string_literal: true
class UnsubmittedCoursesController < ApplicationController
  respond_to :html

  def index
    @courses_list = Course.unsubmitted.order(created_at: :desc)
    @presenter = CoursesPresenter.new(current_user: current_user, courses_list: @courses_list)
  end
end
