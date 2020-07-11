# frozen_string_literal: true

require 'oauth'
require_dependency "#{Rails.root}/lib/wiki_edits"
require_dependency "#{Rails.root}/lib/list_course_manager"
require_dependency "#{Rails.root}/lib/tag_manager"
require_dependency "#{Rails.root}/lib/course_creation_manager"
require_dependency "#{Rails.root}/app/workers/update_course_worker"
require_dependency "#{Rails.root}/app/workers/notify_untrained_users_worker"
require_dependency "#{Rails.root}/app/workers/announce_course_worker"

#= Controller for course functionality
class CoursesController < ApplicationController
  include CourseHelper
  respond_to :html, :json
  before_action :require_permissions, only: %i[notify_untrained
                                               delete_all_weeks]

  ################
  # CRUD methods #
  ################

  def create
    require_signed_in
    course_creation_manager = CourseCreationManager.new(course_params, wiki_params,
                                                        initial_campaign_params,
                                                        instructor_role_description, current_user)
    unless course_creation_manager.valid?
      render json: { message: course_creation_manager.invalid_reason },
             status: :not_found
      return
    end
    @course = course_creation_manager.create
    update_courses_wikis
    update_academic_system
    update_course_format
  end

  def update
    validate
    handle_course_announcement(@course.instructors.first)
    slug_from_params if should_set_slug?
    @course.update update_params
    update_courses_wikis
    update_flags
    ensure_passcode_set
    UpdateCourseWorker.schedule_edits(course: @course, editing_user: current_user)
    render json: { course: @course }
  end

  def destroy
    validate
    DeleteCourseWorker.schedule_deletion(course: @course, current_user: current_user)
    render json: { success: true }
  end

  # /courses/school/title_(term)
  # /courses/school/title_(term)/subpage
  def show
    @course = find_course_by_slug("#{params[:school]}/#{params[:titleterm]}")
    protect_privacy
    verify_edit_credentials { return }
    set_enrollment_details_in_session

    # Only responds to HTML, so spiders fetching index.php will get a 404.
    respond_to do |format|
      format.html { render }
    end
  end

  ##############################
  # Course data json endpoints #
  ##############################

  # /courses/school/title_(term)/course.json
  def course
    set_course
    verify_edit_credentials { return }
  end

  def articles
    set_course
    set_limit
  end

  def revisions
    set_course
    set_course_scoped
    set_limit
  end

  def users
    set_course
  end

  def assignments
    set_course
  end

  def campaigns
    set_course
  end

  def categories
    set_course
  end

  def tags
    set_course
  end

  def timeline
    set_course
  end

  def uploads
    set_course
  end

  ##########################
  # User-initiated actions #
  ##########################

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
      }, status: :not_found
      return
    end
    method = request.request_method.downcase

    manager = ListCourseManager.new(@course, campaign)
    case method
    when 'post'
      manager.handle_post
    when 'delete'
      manager.handle_delete
    end
  end

  def tag
    @course = find_course_by_slug(params[:id])
    TagManager.new(@course).manage(request)
  end

  def manual_update
    @course = find_course_by_slug(params[:id])
    UpdateCourseStats.new(@course, full: true) if user_signed_in?
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

  ##################
  # Helper methods #
  ##################

  private

  def set_course
    @course = find_course_by_slug(params[:slug])
    protect_privacy
  end

  def campaign_params
    params.require(:campaign).permit(:title)
  end

  def validate
    slug = params[:id].gsub(/\.json$/, '')
    @course = find_course_by_slug(slug)
    raise NotPermittedError unless current_user&.can_edit?(@course)
  end

  def handle_course_announcement(instructor)
    # Course announcements aren't particularly necessary, but we'll keep them on
    # for Wiki Ed for now.
    return unless Features.wiki_ed?
    newly_submitted = !@course.submitted? && course_params[:submitted] == true
    return unless newly_submitted
    # Needs to be switched to submitted before the announcement edits are made
    @course.update(submitted: true)
    AddSubmittedTag.new(@course)
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
    slug << "_(#{course[:term]})" if course[:term].present?

    course[:slug] = slug.tr(' ', '_')
  end

  def ensure_passcode_set
    return unless course_params[:passcode].nil?
    @course.update_attribute(:passcode, GeneratePasscode.call)
  end

  def initial_campaign_params
    params
      .require(:course)
      .permit(:initial_campaign_id, :template_description)
  end

  def wiki_params
    params
      .require(:course)
      .fetch(:home_wiki, {})
      .permit(:language, :project)
  end

  def courses_wikis_params
    params
      .require(:course)
      .permit(wikis: [:language, :project])
  end

  def update_courses_wikis
    multi_wikis = courses_wikis_params[:wikis]
    return if multi_wikis.nil?
    new_wikis = multi_wikis.map do |wiki|
      Wiki.get_or_create(language: wiki[:language], project: wiki[:project])
    end
    @course.update_wikis(new_wikis)
  end

  def update_flags
    update_boolean_flag :timeline_enabled
    update_boolean_flag :wiki_edits_enabled
    update_boolean_flag :online_volunteers_enabled
    update_boolean_flag :stay_in_sandbox
    update_edit_settings
    update_academic_system
    update_course_format
    update_last_reviewed
  end

  def update_boolean_flag(flag)
    case params.dig(:course, flag)
    when true
      @course.flags[flag] = true
      @course.save
    when false
      @course.flags[flag] = false
      @course.save
    end
  end

  EDIT_SETTING_KEYS = %w[
    wiki_course_page_enabled assignment_edits_enabled enrollment_edits_enabled
  ].freeze
  def update_edit_settings
    update_flags = {}
    EDIT_SETTING_KEYS.each do |key|
      update_flags[key] = params.dig(:course, key)
    end
    @course.flags['edit_settings'] = update_flags
    @course.save
  end

  def update_academic_system
    @course.flags['academic_system'] = params.dig(:course, 'academic_system')
    @course.save
  end

  def update_course_format
    @course.flags['format'] = params.dig(:course, 'format')
    @course.save
  end

  def update_last_reviewed
    username = params.dig(:course, 'last_reviewed', 'username')
    timestamp = params.dig(:course, 'last_reviewed', 'timestamp')
    if username && timestamp
      @course.flags['last_reviewed'] = {
        'username' => username,
        'timestamp' => timestamp
      }
      @course.save
    end
  end

  def course_params
    params
      .require(:course)
      .permit(:id, :title, :description, :school, :term, :slug, :subject,
              :expected_students, :start, :end, :submitted, :passcode,
              :timeline_start, :timeline_end, :day_exceptions, :weekdays,
              :no_day_exceptions, :cloned_status, :type, :level, :private, :withdrawn)
  end

  def update_params
    course_attributes = course_params.to_h

    if params[:course].key?(:home_wiki)
      home_wiki = Wiki.get_or_create language: params.dig(:course, :home_wiki, :language),
                                     project: params.dig(:course, :home_wiki, :project)
      course_attributes[:home_wiki_id] = home_wiki[:id]
    end

    course_attributes.delete(:passcode) if params[:course][:passcode] == '****'

    course_attributes
  end

  def instructor_role_description
    params.require(:course).permit(:role_description)[:role_description]
  end

  def set_limit
    @limit = params[:limit]
  end

  def set_course_scoped
    @course_scoped = params[:course_scoped] == 'true'
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
    # Admins and enrolled users have non-visitor roles
    return if current_user && current_user.role(@course) != CoursesUsers::Roles::VISITOR_ROLE
    raise ActionController::RoutingError, 'not found'
  end

  # If this is an enroll link, save the slug and enroll code
  # in the session so that it can be used upon successful
  # oauth login.
  # The session data will be used in
  # OmniauthCallbacksController.
  def set_enrollment_details_in_session
    return unless params.key? 'enroll'
    session['course_slug'] = @course.slug
    session['enroll_code'] = params['enroll'] || ''
  end
end
