# frozen_string_literal: true

json.training_modules do
  json.array! @training_modules do |tm|
    json.name tm.translated_name
    json.call(tm, :id, :status, :slug, :kind)
  end
end

json.training_libraries @training_libraries do |library|
  json.slug library.slug
  json.modules library.categories.pluck('modules').flatten.pluck('slug')
end
