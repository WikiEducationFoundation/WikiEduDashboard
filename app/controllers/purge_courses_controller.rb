# frozen_string_literal: true

#= Admin-only page for purging the timeslices of one course by hand. The admin looks
#= the course up first, to see whether it passes the purge checks, and then queues
#= PurgeCourseTimeslicesWorker for it. Only cheap queries run here (see
#= PurgeCourseTimeslicesWorker.failed_checks), since courses can be huge.
class PurgeCoursesController < ApplicationController
  before_action :require_admin_permissions
  before_action :set_course

  CHECK_LABELS = {
    purgeable: 'Purgeable flag set',
    not_finalized: 'Not already finalized',
    ended_long_ago: 'Ended more than 6 months ago',
    no_update_running: 'No update running',
    no_full_update_pending: 'No full update pending',
    no_timeslices_pending: 'No timeslices pending update or reaggregation'
  }.freeze

  def self.not_eligible_message(failed_checks)
    "Course not eligible: #{failed_checks.map { |check| CHECK_LABELS[check] }.join(', ')}"
  end

  def show
    return unless @course
    @failed_checks = PurgeCourseTimeslicesWorker.failed_checks(@course)
  end

  def purge
    return redirect_to(purge_courses_path, flash: { error: 'Course not found' }) unless @course

    failed_checks = PurgeCourseTimeslicesWorker.failed_checks(@course)
    if failed_checks.empty?
      PurgeCourseTimeslicesWorker.schedule_purge(@course)
      flash[:notice] = 'Purge queued'
    else
      flash[:error] = self.class.not_eligible_message(failed_checks)
    end
    redirect_to purge_courses_path(course_id: @course.id)
  end

  private

  def set_course
    return if params[:course_id].blank?
    @course = Course.find_by(id: params[:course_id].strip)
  end

  def purge_courses_path(course_id: nil)
    course_id ? "/purge_courses?#{{ course_id: }.to_query}" : '/purge_courses'
  end
end
