# frozen_string_literal: true

require 'oauth'
require "#{Rails.root}/lib/wiki_edits"
require "#{Rails.root}/lib/list_course_manager"
require "#{Rails.root}/lib/tag_manager"
require "#{Rails.root}/lib/course_creation_manager"
require "#{Rails.root}/app/workers/update_course_worker"
require "#{Rails.root}/app/workers/notify_untrained_users_worker"
require "#{Rails.root}/app/workers/announce_course_worker"

#= Controller for course functionality
class CoursesController < ApplicationController
  include CourseHelper
  respond_to :html, :json
  before_action :require_permissions, only: %i[create
                                               update
                                               destroy
                                               notify_untrained
                                               update_syllabus
                                               delete_all_weeks]

  ################
  # CRUD methods #
  ################

  def create
    course_creation_manager = CourseCreationManager.new(course_params, wiki_params,
                                                        initial_campaign_params,
                                                        instructor_role_description, current_user)
    unless course_creation_manager.valid?
      render json: { message: course_creation_manager.invalid_reason },
             status: 404
      return
    end
    # TODO: Add strict datetime validations to course creation and
    # add a clause to handle validation errors
    @course = course_creation_manager.create
  end

  def update
    validate
    handle_course_announcement(@course.instructors.first)
    slug_from_params if should_set_slug?
    @course.update course_params
    set_timeline_enabled
    ensure_passcode_set
    UpdateCourseWorker.schedule_edits(course: @course, editing_user: current_user)
    render json: { course: @course }
  end

  def destroy
    validate
    DeleteCourseWorker.schedule_deletion(course: @course, current_user: current_user)
    render json: { success: true }
  end

  ########################
  # View support methods #
  ########################

  def show
    @course = find_course_by_slug("#{params[:school]}/#{params[:titleterm]}")
    verify_edit_credentials { return }
    protect_privacy { return }
    set_endpoint
    set_limit

    respond_to do |format|
      format.html { render }
      format.json { render @endpoint }
    end
  end

  def update_syllabus
    @course = Course.find(params[:id])
    handle_syllabus_params
    if @course.save
      render json: { success: true, url: @course.syllabus.url }
    else
      render json: { message: I18n.t('error.invalid_file_format') },
             status: :unprocessable_entity
    end
  end

  ##################
  # Helper methods #
  ##################

  def check
    course_exists = Course.exists?(slug: params[:id])
    render json: { course_exists: course_exists }
  end

  # JSON method for listing/unlisting course
  def list
    @course = find_course_by_slug(params[:id])
    campaign = Campaign.find_by(title: campaign_params[:title])
    unless campaign
      render json: {
        message: "Sorry, #{campaign_params[:title]} is not a valid campaign."
      }, status: 404
      return
    end
    ListCourseManager.new(@course, campaign, request).manage
  end

  def tag
    @course = find_course_by_slug(params[:id])
    TagManager.new(@course).manage(request)
  end

  def manual_update
    @course = find_course_by_slug(params[:id])
    UpdateCourseRevisions.new(@course) if user_signed_in?
    redirect_to "/courses/#{@course.slug}"
  end

  def needs_update
    @course = find_course_by_slug(params[:id])
    @course.update_attribute(:needs_update, true)
    render json: { result: I18n.t('courses.creator.update_scheduled') },
           status: :ok
  end

  def notify_untrained
    @course = find_course_by_slug(params[:id])
    NotifyUntrainedUsersWorker.schedule_notifications(course: @course, notifying_user: current_user)
    render plain: '', status: :ok
  end
  helper_method :notify_untrained

  def delete_all_weeks
    @course = find_course_by_slug(params[:id])
    @course.weeks.destroy_all
    render plain: '', status: :ok
  end

  private

  def campaign_params
    params.require(:campaign).permit(:title)
  end

  def handle_syllabus_params
    syllabus = params['syllabus']
    if syllabus == 'null'
      @course.syllabus.destroy
      @course.syllabus = nil
    else
      @course.syllabus = params['syllabus']
    end
  end

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
    %i[title school].all? { |key| params[:course].key?(key) }
  end

  def slug_from_params(course = params[:course])
    slug = +"#{course[:school]}/#{course[:title]}"
    slug << "_(#{course[:term]})" unless course[:term].blank?

    course[:slug] = slug.tr(' ', '_')
  end

  def ensure_passcode_set
    return unless course_params[:passcode].nil?
    @course.update_attribute(:passcode, Course.generate_passcode)
  end

  def initial_campaign_params
    params
      .require(:course)
      .permit(:initial_campaign_id, :template_description)
  end

  def wiki_params
    params
      .require(:course)
      .permit(:language, :project)
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
              :no_day_exceptions, :cloned_status, :type, :level, :private)
  end

  def instructor_role_description
    params.require(:course).permit(:role_description)[:role_description]
  end

  SHOW_ENDPOINTS = %w[articles assignments campaigns categories check course
                      revisions tag tags timeline uploads users].freeze
  # Show responds to multiple endpoints to provide different sets of json data
  # about a course. Checking for a valid endpoint prevents an arbitrary render
  # vulnerability.
  def set_endpoint
    @endpoint = params[:endpoint] if SHOW_ENDPOINTS.include?(params[:endpoint])
  end

  def set_limit
    @limit = params[:limit] if (params[:endpoint] = 'revisions')
  end

  # If the user could make an edit to the course, this verifies that
  # their tokens are working. If their credentials are found to be invalid,
  # they get logged out immediately, and this method redirects them to the home
  # page, so that they don't make edits that fail upon save.
  # We don't need to do this too often, though.
  def verify_edit_credentials
    return if Features.disable_wiki_output?
    return unless current_user&.can_edit?(@course)
    return if current_user.wiki_token && current_user.updated_at > 12.hours.ago
    return if WikiEdits.new.oauth_credentials_valid?(current_user)
    redirect_to root_path
    yield
  end

  def protect_privacy
    return unless @course.private
    return if current_user&.can_edit?(@course)
    raise ActionController::RoutingError, 'not found'
  end
end
