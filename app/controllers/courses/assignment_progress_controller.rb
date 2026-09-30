# frozen_string_literal: true

#= Data for the course page's Assignments tab: class-wide progress on each
# assignment the Dashboard tracks, for the course's instructors (and anyone
# else who can edit the course). Only for course types that have the tab.
class Courses::AssignmentProgressController < ApplicationController
  include CourseHelper

  before_action :require_permissions

  # GET /courses/:slug/assignment_progress.json[?item=<key>]
  # The students, the assignments and a per-assignment summary; with `item`,
  # also that assignment's per-student rows.
  def index
    @course = find_course_by_slug(params[:slug])
    return head(:not_found) unless @course.assignments_tab_enabled?

    @presenter = AssignmentProgressPresenter.new(course: @course)
    return if params[:item].blank?

    @item = @presenter.item(params[:item])
    head(:not_found) if @item.nil?
  end
end
