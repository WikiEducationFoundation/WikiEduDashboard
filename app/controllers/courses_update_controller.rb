# frozen_string_literal: true

require "#{Rails.root}/app/workers/update_course_worker"
require "#{Rails.root}/app/workers/announce_course_worker"

class CoursesUpdateController < ApplicationController
  include CourseHelper
  respond_to :html, :json

  before_action :require_permissions, 
                only: [:update, :validate]

################
  # CRUD methods #
  ################

  def update
    validate
    handle_course_announcement(@course.instructors.first)
    slug_from_params if should_set_slug?
    @course.update update_params
    update_courses_wikis
    update_course_wiki_namespaces
    update_flags
    ensure_passcode_set
    UpdateCourseWorker.schedule_edits(course: @course, editing_user: current_user)
    render json: { course: @course }
    rescue Wiki::InvalidWikiError => e
    message = I18n.t('courses.error.invalid_wiki', domain: e.domain)
    render json: { errors: e, message: },
           status: :not_found
  end

  ##################
  # Helper methods #
  ##################

  private

  def validate
    slug = params[:id].gsub(/\.json$/, '')
    @course = find_course_by_slug(slug)
    return unless user_signed_in? && current_user.instructor?(@course)
  end

  def handle_course_announcement(instructor)
    # Course announcements aren't particularly necessary, but we'll keep them on
    # for Wiki Ed for now.
    return unless Features.wiki_ed?
    newly_submitted = !@course.submitted? && course_params[:submitted] == true
    return unless newly_submitted
    CourseSubmissionMailerWorker.schedule_email(@course, instructor)
    AnnounceCourseWorker.schedule_announcement(course: @course,
                                               editing_user: current_user,
                                               instructor: instructor)
  end
  
  def should_set_slug?
    %i(title school).all? { |key| params[:course].key?(key) }
  end

  def slug_from_params(course = params[:course])
    slug = String.new("#{course[:school]}/#{course[:title]}")
    slug << "_(#{course[:term]})" unless course[:term].blank?

    course[:slug] = slug.tr(' ', '_')
  end

  def ensure_passcode_set
    return unless course_params[:passcode].nil?
    @course.update_attribute(:passcode, Course.generate_passcode)
  end

  def set_timeline_enabled
    case params.dig(:course, :timeline_enabled)
    when true
      @course.flags[:timeline_enabled] = true
      @course.save
    when false
      @course.flags[:timeline_enabled] = false
      @course.save
    end
  end

  def course_params
    params
      .require(:course)
      .permit(:id, :title, :description, :school, :term, :slug, :subject,
              :expected_students, :start, :end, :submitted, :passcode,
              :timeline_start, :timeline_end, :day_exceptions, :weekdays,
              :no_day_exceptions, :cloned_status, :type)
  end
end