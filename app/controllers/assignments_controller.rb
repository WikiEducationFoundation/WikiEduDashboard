# frozen_string_literal: true

require 'uri'
require_dependency "#{Rails.root}/lib/assignment_manager"
require_dependency "#{Rails.root}/lib/wiki_course_edits"
require_dependency "#{Rails.root}/app/workers/update_assignments_worker"
require_dependency "#{Rails.root}/app/workers/update_course_worker"

# Controller for Assignments
class AssignmentsController < ApplicationController
  respond_to :json
  before_action :set_course, except: [:claim, :update_status]

  def destroy
    set_assignment { return }
    @course = @assignment.course
    check_permissions(@assignment.user_id)
    remove_assignment_template
    @assignment.destroy
    update_onwiki_course_and_assignments
    render json: { assignmentId: @assignment.id }
  end

  # For creating single assignments
  def create
    check_permissions(assignment_params[:user_id].to_i)
    set_wiki { return }
    set_new_assignment
    update_onwiki_course_and_assignments
    render partial: 'assignment', locals: { assignment: @assignment, course: @assignment.course }
  rescue AssignmentManager::DiscouragedArticleError => e
    render json: { errors: e, message: e.message },
           status: :unprocessable_entity
  rescue AssignmentManager::DuplicateAssignmentError => e
    render json: { errors: e, message: e.message || I18n.t('assignments.already_exists') },
           status: :internal_server_error
  end

  # For creating random peer assignments to whole class
  def assign_reviewers_randomly
    check_permissions

    create_random_peer_reviews
    update_onwiki_course_and_assignments
    # Redirecting to give full list of course assignments after
    # creating a bunch of random peer assignments
    redirect_to "/courses/#{@course.slug}/assignments.json"
  end

  # Select an Available Article as a new Assignment for a user
  def claim
    @claimed_assignment = Assignment.find(params[:assignment_id])
    @course = @claimed_assignment.course
    check_permissions(assignment_params[:user_id].to_i)
    check_participation # prevents a user from a different course claiming an assignment

    if @claimed_assignment.user_id
      render json: { message: 'This assignment has been claimed already. Please refresh.' },
             status: :conflict
    else
      claim_assignment # sets @assignment
      render partial: 'updated_assignment', locals: { assignment: @assignment }
    end
  rescue AssignmentManager::DuplicateAssignmentError => e
    render json: { errors: e, message: I18n.t('assignments.already_exists') },
           status: :conflict
  end

  def update_status
    @assignment = Assignment.find(assignment_params[:id])
    @course = @assignment.course
    check_permissions(assignment_params[:user_id].to_i)

    if assignment_params[:status]
      @assignment.update_status(assignment_params[:status])
      render partial: 'updated_assignment', locals: { assignment: @assignment }
    else
      render json: { errors: @assignment.errors, message: 'unable to update assignment' },
             status: :unprocessable_entity
    end
  end

  # Updates the sandbox url of an assignment.
  def update_sandbox_url
    check_permissions(params[:user_id].to_i).then { set_assignment }
    render SandboxUrlUpdator.new(params[:newUrl], @assignment).update
  end

  private

  def update_onwiki_course_and_assignments
    UpdateAssignmentsWorker.schedule_edits(course: @course, editing_user: current_user)
    UpdateCourseWorker.schedule_edits(course: @course, editing_user: current_user)
  end

  def remove_assignment_template
    # This is done syncronously because the assignment gets destroyed.
    WikiCourseEdits.new(action: :remove_assignment, course: @course, current_user:,
                        assignment: @assignment)
  end

  def set_course
    @course = Course.find_by(slug: params[:course_slug])
  end

  def set_assignment
    find_assignment_by_id
    return unless @assignment.nil?
    set_wiki { yield }
    find_assignment_by_params
    return unless @assignment.nil?
    render json: { message: t('error.invalid_assignment') }, status: :not_found
    yield
  end

  def find_assignment_by_id
    @id = params[:id]
    @assignment = Assignment.find_by(id: @id)
  end

  def find_assignment_by_params
    clean_title = params[:article_title].tr(' ', '_')
    @assignment ||= Assignment.find_by(user_id: params[:user_id], role: params[:role],
                                       wiki_id: @wiki.id, article_title: clean_title,
                                       course_id: @course.id)
  end

  def set_wiki
    find_or_create_wiki
  rescue Wiki::InvalidWikiError
    render json: { message: t('error.invalid_assignment') }, status: :not_found
    yield
  end

  def find_or_create_wiki
    home_wiki = @course.home_wiki
    language = params[:language].presence || home_wiki.language
    project = params[:project].presence || home_wiki.project
    @wiki = Wiki.get_or_create(language:, project:) || home_wiki
  end

  def set_new_assignment
    @assignment = AssignmentManager.new(user_id: assignment_params[:user_id],
                                        course: @course, wiki: @wiki,
                                        title: assignment_params[:title].strip,
                                        role: assignment_params[:role]).create_assignment
  end

  def claim_assignment
    @assignment = AssignmentManager.new(user_id: assignment_params[:user_id],
                                        course: @course).claim_assignment(@claimed_assignment)
  end

  def create_random_peer_reviews
    AssignmentManager.new(course: @course).create_random_peer_reviews
  end

  # user_id = nil is when it is not passed in query parameters
  # and in that case we only check if the current user can edit
  # the course (valid for randomly assigning reviewers)
  def check_permissions(user_id = nil)
    require_signed_in
    return if current_user.can_edit?(@course)
    return if user_id.present? && current_user.id == user_id
    raise NotPermittedError
  end

  def check_participation
    return if current_user.nonvisitor?(@course)
    raise ParticipatingUserError
  end

  def assignment_params
    params.permit(
      :id, :user_id, :course_id, :title, :role, :language, :project, :status,
      :course_slug, :format, assignment: {}
    )
  end
end
