# frozen_string_literal: true
json.training_modules @assigned_training_modules do |training_module|
  json.module_name training_module.name
  training_progress_manager = TrainingProgressManager.new(@user, training_module)
  json.completed training_progress_manager.module_completed?
  json.completion_date training_progress_manager.completion_date
end
