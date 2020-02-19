# frozen_string_literal: true

json.user do
  json.training_modules @user.training_modules_users do |tmu|
    training_module = TrainingModule.find_by(id: tmu.training_module_id)
    if training_module
      json.id training_module.id
      json.kind training_module.kind
      json.module_name training_module.name
      tp_manager = TrainingProgressManager.new(@user, training_module, training_module_user: tmu)
      json.status tp_manager.status
      json.completion_date tp_manager.completion_date
    end
  end
end
