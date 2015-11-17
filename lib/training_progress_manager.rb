class TrainingProgressManager
  def initialize(user, training_module, slide=nil)
    @user = user
    @training_module = training_module
    @slide = slide
    @tmu = TrainingModulesUsers.find_by(
      user_id: @user.id,
      training_module_id: @training_module.try(:id)
    ) if @user.present?
  end

  def slide_completed?
    last_slide = @tmu.present? ? TrainingSlide.find_by(slug: @tmu.last_slide_completed) : nil
    return false unless last_slide.present?
    slug_index(last_slide) >= slug_index(@slide)
  end

  def slide_enabled?
    return true if slide_completed? || @user.nil?
    (@tmu.nil? || @tmu.last_slide_completed.nil?) && slug_index(@slide) == 0
  end

  def module_completed?
    return unless @user.present? && @tmu.present?
    @tmu.completed_at.present?
  end

  # For display on training modules overview,
  # where modules could belong to any number of courses
  def assignment_status_css_class
    return 'completed' if module_completed?
    overall_due_date.present? && overall_due_date < Date.today ? 'overdue' : nil
  end
  alias_method :assignment_deadline_status, :assignment_status_css_class

  def assignment_status
    return unless due_date_manager.blocks_with_module_assigned(@training_module).any?
    parenthetical = "due #{overall_due_date}"
    "Training Assignment (#{module_completed? ? 'completed' : parenthetical})"
  end

  def current_slide_further_than_previous?(previous_slug)
    slug_index(@slide) > slug_index(previous_slug)
  end

  def module_progress
    return unless module_started?
    last_completed_index = slug_index(@tmu.last_slide_completed)
    quotient = (last_completed_index + 1) / @training_module.slides.length.to_f
    percentage = (quotient * 100).round
    module_completed? ? 'Complete' : "#{percentage}% Complete"
  end

  private

  def overall_due_date
    due_date_manager.overall_due_date
  end

  def due_date_manager
    TrainingModuleDueDateManager.new(course: nil, training_module: @training_module, user: @user)
  end

  def module_started?
    @user && @tmu && @tmu.last_slide_completed.present? && @training_module.slides
  end

  def slug_index(entity)
    # it's either a slide or a slug
    slug = entity.respond_to?(:slug) ? entity.slug : entity
    index = @training_module.slides.collect(&:slug).index(slug)
    # If passed a slug that isn't part of the module — which may happen because
    # of changes to the module content — then return 0, representing the beginning
    # of the module.
    index = 0 if index.nil?
    index
  end
end
