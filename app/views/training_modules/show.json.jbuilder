json.training_module do
  json.(@training_module, :slug, :id, :slug, :intro)
  json.slides @training_module.slides do |slide|
    json.(slide, :title, :summary, :slug, :id, :content, :assessment)
    json.index @training_module.slides.collect(&:slug).index(slide.slug) + 1
    completion_manager = TrainingProgressManager.new(current_user, @training_module, slide)
    json.completed completion_manager.slide_completed?
    json.enabled completion_manager.slide_enabled?
  end
end
