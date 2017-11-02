# frozen_string_literal: true

json.training_module do
  json.call(@training_module, :slug, :id, :slug)
  json.slides @training_module.slides do |slide|
    json.call(slide, :title_prefix, :title, :summary, :slug, :id, :content,
              :assessment, :translations, :buttonText)
    json.index @training_module.slides.collect(&:slug).index(slide.slug) + 1
    progress_manager = TrainingProgressManager.new(current_user, @training_module, slide)
    json.completed progress_manager.slide_completed?
    json.enabled progress_manager.slide_enabled?
  end
end
