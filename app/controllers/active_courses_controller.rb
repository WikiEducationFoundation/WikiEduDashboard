# frozen_string_literal: true

class ActiveCoursesController < ApplicationController
  respond_to :html

  def index
    @courses_list = Course.strictly_current.where('end < ?', 3.days.from_now)
    @presenter = CoursesPresenter.new(current_user: current_user, courses_list: @courses_list)
  end
end
