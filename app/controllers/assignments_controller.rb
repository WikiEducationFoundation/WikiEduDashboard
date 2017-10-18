# frozen_string_literal: true

require 'uri'
require "#{Rails.root}/lib/assignment_manager"
require "#{Rails.root}/lib/wiki_course_edits"
require "#{Rails.root}/app/workers/update_assignments_worker"
require "#{Rails.root}/app/workers/update_course_worker"

# Controller for Assignments
class AssignmentsController < ApplicationController
  respond_to :json
  before_action :set_course, except: [:update]

  def index
    @assignments = Assignment.where(user_id: params[:user_id],
                                    role: params[:role],
                                    course_id: @course.id)
    render json: @assignments
  end

  def destroy
    set_assignment { return }
    @course = @assignment.course
    check_permissions(@assignment.user_id)
    remove_assignment_template
    @assignment.destroy
    update_onwiki_course_and_assignments
    render json: { article: @id }
  end

  def create
    check_permissions(assignment_params[:user_id].to_i)
    set_wiki { return }
    set_new_assignment
    update_onwiki_course_and_assignments
    render json: @assignment
  rescue AssignmentManager::DuplicateAssignmentError => e
    render json: { errors: e }, status: 500
  end

  def update
    check_permissions(assignment_params[:user_id].to_i)
    @assignment = Assignment.find(assignment_params[:id])
    if @assignment.update_attributes(assignment_params)
      render partial: 'updated_assignment', locals: { assignment: @assignment }
    else
      render json: { errors: @assignment.errors, message: 'unable to update assignment' },
             status: 500
    end
  end

  private

  def update_onwiki_course_and_assignments
    UpdateAssignmentsWorker.schedule_edits(course: @course, editing_user: current_user)
    UpdateCourseWorker.schedule_edits(course: @course, editing_user: current_user)
  end

  def remove_assignment_template
    # This is done syncronously because the assignment gets destroyed.
    WikiCourseEdits.new(action: :remove_assignment, course: @course, current_user: current_user,
                        assignment: @assignment)
  end

  def set_course
    @course = Course.find_by_slug(URI.unescape(params[:course_id]))
  end

  def set_assignment
    find_assignment_by_id
    return unless @assignment.nil?
    set_wiki { yield }
    find_assignment_by_params
    return unless @assignment.nil?
    render json: { message: t('error.invalid_assignment') }, status: 404
    yield
  end

  def find_assignment_by_id
    @id = params[:id]
    @assignment = Assignment.find_by(id: @id)
  end

  def find_assignment_by_params
    clean_title = params[:article_title].tr(' ', '_')
    @assignment ||= Assignment.find_by(user_id: params[:user_id],
                                       role: params[:role],
                                       wiki_id: @wiki.id,
                                       article_title: clean_title,
                                       course_id: @course.id)
  end

  def set_wiki
    find_or_create_wiki
  rescue Wiki::InvalidWikiError
    render json: { message: t('error.invalid_assignment') }, status: 404
    yield
  end

  def find_or_create_wiki
    home_wiki = @course.home_wiki
    language = params[:language].present? ? params[:language] : home_wiki.language
    project = params[:project].present? ? params[:project] : home_wiki.project
    @wiki = Wiki.get_or_create(language: language, project: project) || home_wiki
  end

  def set_new_assignment
    @assignment = AssignmentManager.new(user_id: assignment_params[:user_id],
                                        course: @course,
                                        wiki: @wiki,
                                        title: assignment_params[:title],
                                        role: assignment_params[:role]).create_assignment
  end

  def check_permissions(user_id)
    require_signed_in
    return if current_user.id == user_id
    return if current_user.can_edit?(@course)
    raise NotPermittedError
  end

  def assignment_params
    params.permit(:id, :user_id, :course_id, :title, :role, :language, :project)
  end
end
