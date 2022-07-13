# frozen_string_literal: true

class ActiveCoursesController < ApplicationController
  respond_to :json, :html

  def index
    respond_to do |format|
      format.html { render }
      format.json do
        courses_list = Course.strictly_current.where('end < ?', 3.days.from_now)
        presenter = CoursesPresenter.new(current_user: current_user, courses_list: courses_list)
        @courses = presenter.active_courses_by_recent_edits
      end
    end
  end
end
