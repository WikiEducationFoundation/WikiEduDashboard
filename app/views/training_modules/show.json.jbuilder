# frozen_string_literal: true
progress_manager = TrainingProgressManager.new(current_user, @training_module)

json.training_module do
  json.call(@training_module, :slug, :id, :wiki_page)
  json.slides @training_module.slides do |slide|
    json.call(slide, :title_prefix, :title, :summary, :slug, :id, :content,
              :translations, :wiki_page)
    json.assessment slide.assessment.presence
    json.buttonText slide.button_text
    json.index @training_module.slides.collect(&:slug).index(slide.slug) + 1
    json.completed progress_manager.slide_completed?(slide)
    json.enabled progress_manager.slide_enabled?(slide)
  end
end
