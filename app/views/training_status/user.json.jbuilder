# frozen_string_literal: true

json.user do
  json.training_modules @training_modules do |training_module|
    json.id training_module.id
    json.module_name training_module.name
    training_progress_manager = TrainingProgressManager.new(@user, training_module)
    json.status training_progress_manager.status
    json.completion_date training_progress_manager.completion_date
  end
end
