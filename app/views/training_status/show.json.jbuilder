# frozen_string_literal: true

json.course do
  json.training_modules @assigned_training_modules do |training_module|
    training_progress_manager = TrainingProgressManager.new(@user, training_module)

    json.id training_module.id
    json.module_name training_module.name
    json.kind training_module.kind
    json.status training_progress_manager.status
    json.completion_date training_progress_manager.completion_date
    json.completion_time training_progress_manager.completion_time
  end
end
