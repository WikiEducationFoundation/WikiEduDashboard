# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/timeslice_manager"

#= Controller for requesting and updating timeslice duration
class TimesliceDurationController < ApplicationController
  respond_to :html
  before_action :require_super_admin_permissions, :set_course
  def index; end

  def show
    timeslice_manager = TimesliceManager.new(@course)
    @results = @course.wikis.index_with { |wiki| timeslice_manager.timeslice_duration(wiki) }
    render :update
  rescue NoMethodError
    redirect_to(timeslice_duration_path)
  end

  def update
    wiki = Wiki.find(params[:wiki_id])
    timeslice_duration = params[:duration].to_i
    update_duration_flag(wiki, timeslice_duration)
    redirect_to(timeslice_duration_path,
                notice: "Timeslice duration updated for course id #{@course.id} wiki id #{wiki.id}")
  rescue ActiveRecord::RecordNotFound
    redirect_to(timeslice_duration_path,
                flash: { error: 'Wiki not found' })
  end

  private

  def update_duration_flag(wiki, timeslice_duration)
    # Ensure timeslice_duration flag exists
    @course.flags[:timeslice_duration] ||= { default: TimesliceManager::TIMESLICE_DURATION }
    @course.flags[:timeslice_duration][wiki.domain.to_sym] = timeslice_duration
    @course.save
  end

  def set_course
    return unless params[:course_id].present?
    @course = Course.find(params[:course_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to(timeslice_duration_path,
                flash: { error: 'Course not found' })
  end
end
