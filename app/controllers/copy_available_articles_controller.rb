# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/utils/course_url_parser"
require_dependency "#{Rails.root}/app/workers/update_assignments_worker"
require_dependency "#{Rails.root}/app/workers/update_course_worker"

#= Copies the Available Articles of one course into another
class CopyAvailableArticlesController < ApplicationController
  include CourseHelper
  respond_to :json

  before_action :require_signed_in
  before_action :set_target
  before_action :check_permissions
  before_action :set_source

  # Reports how many articles a copy would add, without changing anything.
  def preview
    @result = copy_available_articles(dry_run: true)
  end

  def create
    @result = copy_available_articles
    update_onwiki_course_and_assignments if @result.created_count.positive?
  end

  private

  def copy_available_articles(dry_run: false)
    CopyAvailableArticles.new(source: @source, target: @target,
                              include_student_assigned: include_student_assigned?,
                              dry_run:)
  end

  def include_student_assigned?
    params[:include_student_assigned].to_s == 'true'
  end

  def set_target
    @target = find_course_by_slug(params[:course_slug])
  end

  def check_permissions
    raise NotPermittedError unless current_user.can_edit?(@target)
  end

  # The source may be given as a slug or as a pasted course URL. It must be
  # visible to the current user under the same rules as
  # CoursesController#protect_privacy; unknown and hidden sources both get a
  # 404 so that the existence of a private course is not revealed.
  def set_source
    parser = CourseUrlParser.new(params[:source])
    @source = parser.course
    if @source.nil? || source_hidden?
      render json: { message: I18n.t('error_no_course.explanation', slug: parser.slug) },
             status: :not_found
    elsif @source == @target
      render json: { message: I18n.t('error.invalid_assignment') },
             status: :unprocessable_content
    end
  end

  def source_hidden?
    @source.private && !current_user.nonvisitor?(@source)
  end

  def update_onwiki_course_and_assignments
    UpdateAssignmentsWorker.schedule_edits(course: @target, editing_user: current_user)
    UpdateCourseWorker.schedule_edits(course: @target, editing_user: current_user)
  end
end
