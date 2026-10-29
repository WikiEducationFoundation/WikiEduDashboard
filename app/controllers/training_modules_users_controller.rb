# frozen_string_literal: true

class TrainingModulesUsersController < ApplicationController
  include CourseHelper
  respond_to :json
  before_action :require_signed_in, only: [:create_or_update, :mark_exercise_complete,
                                            :verify_exercise_article]

  def index
    course = Course.find(params[:course_id])
    require_course_visible(course)
    user = progress_user(course)
    # Without this, the blocks partial would fall back to the viewer's own
    # progress and show it as the requested user's. The Students tab asks
    # for any viewer, so this returns nothing rather than an error.
    return render json: { blocks: [] } if params[:user_id] && user.nil?
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
    return render_article_title_input_error unless @training_module&.article_title_input
    set_training_module_user
    verification = VerifyExerciseArticle.new(training_module_user: @training_module_user,
                                             title: params[:article_title],
                                             courses: courses_for_exercise_article,
                                             confirmed: confirmed_outside_mainspace?)
    render_article_verification(verification)
  end

  def mark_exercise_complete
    block = Block.find(params[:block_id])
    @course = block.course
    raise ParticipatingUserError unless current_user.nonvisitor?(@course)
    set_training_module
    set_training_module_user
    if marking_complete?
      verify_exercise_article_recorded { return }
      verify_exercise_sandbox { return }
    end
    mark_completion_status(marking_complete?, @course.id)

    render 'courses/_block', locals: { block:, course: @course }
  end

  private

  # A user's progress goes only to that user and, for the course's own
  # participants, to people who can edit the course, as in
  # TrainingStatusController.
  def progress_user(course)
    user = User.find_by(id: params[:user_id]) if params[:user_id]
    return unless user && current_user
    return user if current_user.id == user.id || current_user.admin?
    return user if user.course_roles(course).any? && current_user.can_edit?(course)
  end

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

  def render_article_title_input_error
    render json: { status: 'not_found',
                   message: 'This training module does not take an article title.' },
           status: :not_found
  end

  def render_article_verification(verification)
    if verification.verified?
      render json: { status: 'verified', article_title: verification.article_title }
    elsif verification.needs_confirmation?
      render json: { status: 'confirm', article_title: verification.article_title,
                     article_url: verification.article_url,
                     message: t('training.article_title_input.not_mainspace') }
    else
      render json: { status: 'not_found', message: t('training.article_title_input.not_found') },
             status: :unprocessable_entity
    end
  end

  # The student has seen the warning that the page they named isn't a
  # mainspace article, and is submitting it anyway.
  def confirmed_outside_mainspace?
    ActiveModel::Type::Boolean.new.cast(params[:confirmed]) || false
  end

  # Verifying from a course timeline covers just that course. From the training
  # slides, it covers each current course that assigns the module.
  def courses_for_exercise_article
    return [block_course_for_exercise_article] if params[:block_id].present?
    VerifyExerciseArticle.current_courses(user: current_user, training_module: @training_module)
  end

  def block_course_for_exercise_article
    course = Block.find(params[:block_id]).course
    raise ParticipatingUserError unless current_user.nonvisitor?(course)
    course
  end

  # The sandbox check only guards against premature completion, so unmarking an
  # exercise doesn't have to pass it.
  def marking_complete?
    ActiveModel::Type::Boolean.new.cast(params[:complete]) || false
  end

  # For article_title_input exercises, the title is only stored after
  # verify_exercise_article confirmed the edit, so its presence is sufficient.
  def verify_exercise_article_recorded
    return unless @training_module.article_title_input
    return if @training_module_user.exercise_article_title(@course.id).present?

    render json: { message: t('training.exercise_article_unverified'), status: 'incomplete' },
           status: :forbidden
    yield
  end

  def verify_exercise_sandbox
    check = CheckExerciseSandbox.new(training_module_user: @training_module_user,
                                     course: @course)
    return if check.eligible?

    render json: { message: exercise_sandbox_error(check), status: 'incomplete' },
           status: :forbidden
    yield
  end

  def exercise_sandbox_error(check)
    return t('training.exercise_needs_assigned_article') if check.awaiting_article_assignment?

    t('training.exercise_sandbox_incomplete', pages: check.missing_pages.join(', '))
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
