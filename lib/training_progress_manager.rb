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

  def current_slide_further_than_previous?(previous_slug)
    slug_index(@slide) > slug_index(previous_slug)
  end

  def module_progress
    return unless @user && @tmu.last_slide_completed.present?
    quotient = (slug_index(@tmu.last_slide_completed) + 1) / @training_module.slides.length.to_f
    percentage = (quotient * 100).round
    module_completed? ? 'Complete' : "#{percentage}% Complete"
  end

  private

  def slug_index(entity)
    slug = entity.respond_to?(:slug) ? entity.slug : entity
    @training_module.slides.collect(&:slug).index(slug)
  end

end
