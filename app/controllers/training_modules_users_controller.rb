# frozen_string_literal: true

class TrainingModulesUsersController < ApplicationController
  respond_to :json
  before_action :require_signed_in, only: [:create_or_update, :mark_exercise_complete,
                                            :verify_exercise_article]

  def index
    course = Course.find(params[:course_id])
    user = User.find_by(id: params[:user_id]) if params[:user_id]
    render 'courses/_blocks', locals: { blocks: course.blocks, course:, user: }
  end

  def create_or_update
    set_slide
    set_training_module_user
    return if @slide.nil?
    complete_slide if should_set_slide_completed?
    complete_module if last_slide?
    @completed = @training_module_user.completed_at.present?
    render_slide
  end

  def verify_exercise_article
    set_training_module
    set_training_module_user
    article_title = params[:article_title]
    if WikiApi.new(wiki_for_exercise).user_has_edited_article?(current_user.username, article_title)
      @training_module_user.store_exercise_article_title(article_title)
      auto_mark_complete_for_user_courses
      @training_module_user.save
      render json: { status: 'verified', article_title: }
    else
      message = I18n.t('training.article_title_input.not_found')
      render json: { status: 'not_found', message: },
             status: :unprocessable_entity
    end
  end

  def mark_exercise_complete
    set_training_module
    set_training_module_user
    block = Block.find(params[:block_id])
    @course = block.course
    verify_exercise_sandbox { return }
    mark_completion_status(params[:complete], @course.id)

    render 'courses/_block', locals: { block:, course: @course }
  end

  private

  def set_training_module
    @training_module = TrainingModule.find_by(slug: params[:module_id])
  end

  def set_slide
    set_training_module
    @slide = TrainingSlide.find_by(slug: params[:slide_id])
  end

  def render_slide
    render json: { slide: @slide, completed: @completed }
  end

  def set_training_module_user
    @training_module_user = TrainingModulesUsers.create_or_find_by(
      user: current_user,
      training_module_id: @training_module.id
    )
  end

  def complete_slide
    @training_module_user.last_slide_completed = @slide.slug
    @training_module_user.save
  end

  def complete_module
    @training_module_user.update(completed_at: Time.now.utc)
    make_training_module_user_instructor if instructor_orientation_module?
  end

  HOW_TO_TEACH_WITH_WIKIPEDIA_TRAINING_MODULE_ID = 3

  def instructor_orientation_module?
    return false unless Features.wiki_ed?
    @training_module_user.completed_at.present? &&
      (@training_module.id == HOW_TO_TEACH_WITH_WIKIPEDIA_TRAINING_MODULE_ID)
  end

  def last_slide?
    @training_module_user.training_module.slides.last.slug == @slide.slug
  end

  def should_set_slide_completed?
    @training_module_user.furthest_slide?(@slide.slug)
  end

  def wiki_for_exercise
    return Block.find(params[:block_id]).course.home_wiki if params[:block_id].present?
    Wiki.find_by(language: 'en', project: 'wikipedia')
  end

  def auto_mark_complete_for_user_courses
    blocks = Block.joins(week: { course: :courses_users })
                  .where(courses_users: { user_id: current_user.id,
                                         role: CoursesUsers::Roles::STUDENT_ROLE })
                  .where.not('training_module_ids = ?', [].to_yaml)
                  .includes(:week)
    course_ids = blocks.select { |b| b.training_module_ids.include?(@training_module.id) }
                       .map { |b| b.week.course_id }
                       .uniq
    course_ids.each { |cid| @training_module_user.mark_completion(true, cid) }
  end

  def verify_exercise_sandbox
    return if @training_module_user.eligible_for_completion?(@course.home_wiki)

    error_message = exercise_incomplete_message
    render json: { message: error_message, status: 'incomplete' },
           status: :forbidden
    yield
  end

  def exercise_incomplete_message
    if @training_module_user.training_module.sandbox_location
      sandbox = @training_module_user.exercise_sandbox_location
      "Please complete the exercise in your Exercise Sandbox (#{sandbox}) " \
      'before marking it complete'
    else
      'Please verify your Wikipedia edit before marking this exercise complete.'
    end
  end

  def mark_completion_status(value, course_id)
    @training_module_user.mark_completion(value, course_id)
    @training_module_user.save
  end

  def make_training_module_user_instructor
    # Do not downgrade admins' permissions.
    return if @training_module_user.user.admin?

    @training_module_user.user.update(permissions: User::Permissions::INSTRUCTOR)
  end
end
