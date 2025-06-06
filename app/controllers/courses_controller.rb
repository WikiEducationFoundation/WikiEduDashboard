# frozen_string_literal: true

require 'oauth'
require_dependency "#{Rails.root}/lib/wiki_edits"
require_dependency "#{Rails.root}/lib/list_course_manager"
require_dependency "#{Rails.root}/lib/tag_manager"
require_dependency "#{Rails.root}/lib/course_creation_manager"
require_dependency "#{Rails.root}/app/workers/update_course_worker"
require_dependency "#{Rails.root}/app/workers/notify_untrained_users_worker"
require_dependency "#{Rails.root}/app/workers/announce_course_worker"
require_dependency "#{Rails.root}/lib/alerts/check_timeline_alert_manager"

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
                                                        params[:course][:scoping_methods],
                                                        initial_campaign_params,
                                                        instructor_role_description, current_user,
                                                        params[:course][:ta_support])
    unless course_creation_manager.valid?
      render json: { message: course_creation_manager.invalid_reason },
             status: :not_found
      return
    end
    @course = course_creation_manager.create
    # return early if the course was not persisted to the db
    return if @course.id.nil?
    handle_post_course_creation_updates
  end

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

  def destroy
    validate
    DeleteCourseWorker.schedule_deletion(course: @course, current_user:)
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

  def find
    course = Course.find(params[:course_id])
    redirect_to "/courses/#{course.slug}"
  end

  def search
    search_presenter = CoursesPresenter.new(
      current_user:,
      courses_list: Course.where(private: false)
    )
    @query = params[:search]
    @courses = search_presenter.search_courses(@query)
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

  def alerts
    set_course
    @alerts = current_user&.admin? ? @course.alerts : @course.public_alerts
  end

  def classroom_program_students_json
    courses = Course.classroom_program_students
    render json: courses.as_json(
      only: %i[title school slug],
      include: {
        students: {
          only: %i[username]
        }
      }
    )
  end

  def classroom_program_students_and_instructors_json
    courses = Course.classroom_program_students_and_instructors
    render json: courses.as_json(
      only: %i[title school slug],
      include: {
        students: {
          only: %i[username]
        },
        instructors: {
          only: %i[username]
        }
      }
    )
  end

  def fellows_cohort_students_json
    courses = Course.fellows_cohort_students
    render json: courses.as_json(
      only: %i[title school slug],
      include: {
        students: {
          only: %i[username]
        }
      }
    )
  end

  def fellows_cohort_students_and_instructors_json
    courses = Course.fellows_cohort_students_and_instructors
    render json: courses.as_json(
      only: %i[title school slug],
      include: {
        students: {
          only: %i[username]
        },
        instructors: {
          only: %i[username]
        }
      }
    )
  end

  ##########################
  # User-initiated actions #
  ##########################

  def check
    course_exists = Course.exists?(slug: params[:id])
    render json: { course_exists: }
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
    require_super_admin_permissions
    @course = find_course_by_slug(params[:id])
    UpdateCourseStatsTimeslice.new(@course)
    redirect_to "/courses/#{@course.slug}"
  end

  def needs_update
    @course = find_course_by_slug(params[:id])
    @course.update(needs_update: true)
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
    CheckTimelineAlertManager.new(@course)
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
    course_cloned_status = @course.cloned_status == 3
    raise NotPermittedError unless current_user&.can_edit?(@course) || course_cloned_status
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
                                               instructor:)
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
    @course.update(passcode: GeneratePasscode.call)
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

  def course_wiki_namespaces_params
    params.require(:course).permit(namespaces: [])[:namespaces]
  end

  def update_course_wiki_namespaces
    namespaces = course_wiki_namespaces_params || []
    # Each entry in namespaces uses wiki domain and namespace
    # Eg.: for cookbook, its "en.wikibooks.org-namespace-102"
    @course.courses_wikis.each do |course_wiki|
      wiki_domain = course_wiki.wiki.domain
      course_wiki_namespaces = []
      namespaces.each do |ns|
        ns_wiki_domain = ns.split('-', 2)[0]
        next if ns_wiki_domain != wiki_domain
        ns_id = ns.split('-', 3)[2].to_i
        cw_ns = course_wiki.course_wiki_namespaces.find_or_create_by(namespace: ns_id)
        course_wiki_namespaces << cw_ns
      end
      course_wiki.update_namespaces(course_wiki_namespaces)
    end
  end

  def update_flags
    update_boolean_flags
    update_edit_settings
    update_academic_system
    update_course_format
    update_last_reviewed
  end

  UPDATABLE_FLAGS = [
    :timeline_enabled,
    :wiki_edits_enabled,
    :online_volunteers_enabled,
    :disable_student_emails,
    :stay_in_sandbox,
    :no_sandboxes,
    :retain_available_articles
  ].freeze
  def update_boolean_flags
    UPDATABLE_FLAGS.each do |flag|
      case params.dig(:course, flag)
      when true
        @course.flags[flag] = true
      when false
        @course.flags[flag] = false
      end
    end
    @course.save
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

  def update_timeslice_duration
    # Set the default timeslice_duration to the default value
    @course.flags[:timeslice_duration] = { default: TimesliceManager::TIMESLICE_DURATION }
    @course.save
  end

  def update_last_reviewed
    username = params.dig(:course, 'last_reviewed', 'username')
    timestamp = params.dig(:course, 'last_reviewed', 'timestamp')
    return unless username && timestamp
    @course.flags['last_reviewed'] = {
      'username' => username,
      'timestamp' => timestamp
    }
    @course.save
  end

  def handle_post_course_creation_updates
    update_courses_wikis
    update_course_wiki_namespaces
    update_academic_system
    update_course_format
    update_timeslice_duration
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

  # If the user could make an edit to the course, this verifies that
  # their tokens are working. If their credentials are found to be invalid,
  # they get logged out immediately, and this method redirects them to the home
  # page, so that they don't make edits that fail upon save.
  # We don't need to do this too often, though.
  # rubocop:disable Metrics/CyclomaticComplexity
  def verify_edit_credentials
    return if Features.disable_wiki_output?
    return unless @course.home_wiki.edits_enabled?
    return unless current_user&.can_edit?(@course)
    return if current_user.wiki_token && current_user.updated_at > 12.hours.ago
    return if WikiEdits.new(@course.home_wiki).oauth_credentials_valid?(current_user)
    redirect_to root_path
    yield
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def protect_privacy
    return unless @course.private
    # Admins and enrolled users have non-visitor roles
    return if current_user&.nonvisitor?(@course)
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
