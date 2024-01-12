# frozen_string_literal: true

require_dependency Rails.root.join('lib/training_module_due_date_manager')

class TrainingProgressManager
  def initialize(user, training_module, training_module_user: nil)
    @user = user
    @training_module = training_module
    return unless @user.present?
    return if training_module_user == :none
    @tmu = training_module_user
    @tmu ||= TrainingModulesUsers.find_by(user_id: @user.id,
                                          training_module_id: @training_module&.id)
  end

  def slide_completed?(slide)
    return false unless last_completed_slide_slug.present?
    slug_index(last_completed_slide_slug) >= slug_index(slide.slug)
  end

  def slide_enabled?(slide)
    return true if slide_completed?(slide) || @user.nil?
    return true if slug_index(slide.slug).zero?
    false
  end

  def module_completed?
    return false unless @user.present? && @tmu.present?
    @tmu.completed_at.present?
  end

  def completion_date
    return unless @user.present? && @tmu.present?
    @tmu.completed_at
  end

  # For display on training modules overview,
  # where modules could belong to any number of courses
  def assignment_status_css_class
    return 'completed' if module_completed?
    overall_due_date.present? && overall_due_date < Time.zone.today ? 'overdue' : nil
  end
  alias assignment_deadline_status assignment_status_css_class

  # This is shown in the StudentDrawer
  def status
    return I18n.t('training_status.completed') if module_completed?
    return I18n.t('training_status.started') if module_started?
    return I18n.t('training_status.not_started')
  end

  # This is shown for the logged in user where the module is listed
  def assignment_status
    return unless @training_module.training?
    if due_date_manager.blocks_with_module_assigned(@training_module).any?
      parenthetical = I18n.t('training_status.due', due_date: overall_due_date)
      assingment_status = module_completed? ? I18n.t('training_status.completed') : parenthetical
      return I18n.t('training_status.assignment_status', status: assingment_status)
    end
    return I18n.t('training_status.completed') if module_completed?
  end

  def slide_further_than_previous?(slide_slug, previous_slug)
    slug_index(slide_slug) > slug_index(previous_slug)
  end

  def module_progress
    return unless module_started?
    last_completed_index = slug_index(@tmu.last_slide_completed)
    return if last_completed_index.zero?
    quotient = (last_completed_index + 1) / @training_module.slides.length.to_f
    percentage = (quotient * 100).round
    completing = "#{percentage}% #{I18n.t('training_status.completed')}"
    module_completed? ? I18n.t('training_status.completed') : completing
  end

  def completion_time
    return unless module_completed? && @tmu.created_at.present?
    @tmu.completed_at - @tmu.created_at
  end

  private

  def last_completed_slide_slug
    @last_completed_slide_slug ||= @tmu&.last_slide_completed
  end

  def due_date_manager
    @due_date_manager ||= TrainingModuleDueDateManager.new(course: nil,
                                                           training_module: @training_module,
                                                           user: @user)
  end

  def overall_due_date
    return @overall_due_date if @overall_due_date_cached
    @overall_due_date = due_date_manager.overall_due_date
    @overall_due_date_cached = true
    @overall_due_date
  end

  def module_started?
    @user && @tmu && @tmu.last_slide_completed.present? && @training_module.slides
  end

  def slug_index(slug)
    # it's either a slide or a slug
    index = @training_module.slides.collect(&:slug).index(slug)
    # If passed a slug that isn't part of the module — which may happen because
    # of changes to the module content — then return 0, representing the beginning
    # of the module.
    index = 0 if index.nil?
    index
  end
end
