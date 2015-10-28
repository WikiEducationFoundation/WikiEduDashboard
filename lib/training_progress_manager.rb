class TrainingProgressManager

  def initialize(user, training_module, slide=nil)
    @user = user
    @training_module = training_module
    @slide = slide
    @utm = TrainingModulesUsers.find_by(
      user_id: @user.id,
      training_module_id: @training_module.id
    )
  end

  def slide_completed?
    last_slide = TrainingSlide.find_by(slug: @utm.last_slide_completed)
    return false unless last_slide.present?
    slug_index(last_slide) >= slug_index(@slide)
  end

  def slide_enabled?
    return true if slide_completed?
    @utm.last_slide_completed.nil? && slug_index(@slide) == 0
  end

  private

  def slug_index(slide)
    @training_module.slides.collect(&:slug).index(slide.slug)
  end

end
