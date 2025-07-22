# frozen_string_literal: true

json.training_modules do
  json.array! @training_modules do |training_module|
    json.name training_module.name
  end
end
