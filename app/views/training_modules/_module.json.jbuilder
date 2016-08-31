# frozen_string_literal: true
json.training_module do
  json.call(@training_module, :slug)
  json.slides @training_module.slides do |slide|
    json.call(slide, :title, :summary, :slug, :id, :content, :assessment)
  end
end
