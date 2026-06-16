# frozen_string_literal: true

#= Admin-only controller for viewing and setting course flags and needs_update
class CourseFlagsController < ApplicationController
  respond_to :html
  before_action :require_admin_permissions
  before_action :set_course, only: %i[show update]

  MANAGEABLE_FLAGS = %i[use_acuwt very_long_update debug_updates].freeze

  def index; end

  def show
    @manageable_flags = MANAGEABLE_FLAGS
  end

  def update
    return redirect_to(course_flags_path, flash: { error: 'Course not found' }) if @course.nil?
    MANAGEABLE_FLAGS.each do |flag|
      @course.flags[flag] = params[flag] == '1'
    end
    @course.needs_update = params[:needs_update] == '1'
    @course.save
    redirect_to course_flags_show_path(course_id: @course.id),
                notice: "Flags updated for course #{@course.slug}"
  end

  private

  def set_course
    return unless params[:course_id].present?
    @course = Course.find(params[:course_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to course_flags_path, flash: { error: 'Course not found' }
  end
end
