# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/analytics/assignment_progress_csv_builder"

#= Data for the course page's Assignments tab: class-wide progress on each
# assignment the Dashboard tracks, for the course's instructors (and anyone
# else who can edit the course). Only for course types that have the tab.
class Courses::AssignmentProgressController < ApplicationController
  include CourseHelper

  before_action :require_permissions
  before_action :set_course

  # GET /courses/:slug/assignment_progress.json[?item=<key>]
  # The students, the assignments and a per-assignment summary; with `item`,
  # also that assignment's per-student rows.
  def index
    @presenter = AssignmentProgressPresenter.new(course: @course)
    return if params[:item].blank?

    @item = @presenter.item(params[:item])
    head(:not_found) if @item.nil?
  end

  # GET /courses/:slug/assignment_progress.csv
  # Every student's status on every assignment, one row per student.
  def csv
    presenter = AssignmentProgressPresenter.new(course: @course)
    real_names = current_user.can_see_real_names?(@course)
    send_data AssignmentProgressCsvBuilder.new(presenter, real_names:).generate_csv,
              type: 'text/csv', disposition: 'attachment',
              filename: "#{@course.slug}-assignments-#{Time.zone.today}.csv".tr('/', '-')
  end

  private

  def set_course
    @course = find_course_by_slug(params[:slug])
    head(:not_found) unless @course.assignments_tab_enabled?
  end
end
