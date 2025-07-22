# frozen_string_literal: true

class UnsubmittedCoursesController < ApplicationController
  respond_to :html

  def index
    @unsubmitted_courses = Course.unsubmitted.order(created_at: :desc).includes(:tags, :instructors)
  end
end
