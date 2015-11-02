class TrainingProgressManager

  def initialize(user, training_module, slide=nil)
    @user = user
    @training_module = training_module
    @slide = slide
    if @user
      @tmu = TrainingModulesUsers.find_by(
        user_id: @user.id,
        training_module_id: @training_module.id
      )
    end
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
    return unless @user.present?
    @tmu.completed_at.present?
  end

  def assignment_status
    blocks = blocks_with_module_assigned(@training_module)
    return unless blocks.any?
    due_date = block_with_earliest_due_date(blocks).due_date
    "Training Assignment (#{due_date.present? ? "due #{due_date.strftime("%m/%d/%Y")}" : "no due date"})"
  end

  def current_slide_further_than_previous?(previous_slug)
    slug_index(@slide) > slug_index(previous_slug)
  end

  def module_progress
    return unless @user && @tmu && @tmu.last_slide_completed.present? && @training_module.slides
    quotient = (slug_index(@tmu.last_slide_completed) + 1) / @training_module.slides.length.to_f
    percentage = (quotient * 100).round
    module_completed? ? 'Complete' : "#{percentage}% Complete"
  end

  private

  def block_with_earliest_due_date(blocks)
    return blocks.first if blocks.length == 1
    blocks.sort { |a, b| a.due_date <=> b.due_date }
  end

  def blocks_with_module_assigned(training_module)
    blocks_with_training_modules_for_user.select do |block|
      block.training_module_ids.include?(training_module.id)
    end
  end

  def blocks_with_training_modules_for_user
    return [] unless @user.present?
    Block.joins(week: { course: :courses_users})
      .where(courses_users: { user_id: @user.id })
      .where.not('training_module_ids = ?', [].to_yaml)
  end

  def slug_index(entity)
    # it's either a slide or a slug
    slug = entity.respond_to?(:slug) ? entity.slug : entity
    @training_module.slides.collect(&:slug).index(slug)
  end

end
