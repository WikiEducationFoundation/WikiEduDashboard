# frozen_string_literal: true

class UnsubmittedCoursesController < ApplicationController
  respond_to :html

  # Drafts whose start date is further in the past than this are unlikely to
  # ever be submitted, so the default view hides them. `?all=true` shows them.
  START_DATE_CUTOFF = 3.months

  def index
    @show_all = params[:all].present?
    @unsubmitted_courses = scoped_courses.order(created_at: :desc).includes(:tags, :instructors)
  end

  private

  def scoped_courses
    courses = current_user&.admin? ? Course.unsubmitted : Course.unsubmitted.nonprivate
    return courses if @show_all
    courses.where(start: START_DATE_CUTOFF.ago..)
  end
end
