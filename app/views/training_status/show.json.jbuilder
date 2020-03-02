# frozen_string_literal: true

json.course do
  json.training_modules @assigned_training_modules do |training_module|
    tp_manager = TrainingProgressManager.new(@user, training_module)

    json.id training_module.id
    json.module_name training_module.name
    json.kind training_module.kind
    json.status tp_manager.status
    json.completion_date tp_manager.completion_date
    tmu = TrainingModulesUsers.find_by(user_id: @user.id, training_module_id: training_module.id)
    json.completion_time tmu.completed_at - tmu.created_at if tp_manager.completion_date
  end
end
