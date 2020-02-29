# frozen_string_literal: true

json.course do
  json.training_modules @assigned_training_modules do |training_module|
    training_progress_manager = TrainingProgressManager.new(@user, training_module)

    json.id training_module.id
    json.module_name training_module.name
    json.kind training_module.kind
    json.status training_progress_manager.status
    json.completion_date training_progress_manager.completion_date
    tmu = TrainingModulesUsers.find_by(user_id: @user.id, training_module_id: training_module.id)
    if training_progress_manager.completion_date
      json.completion_time Time.at(tmu.completed_at - tmu.created_at)
                               .utc
                               .strftime('%H ' + I18n.t('users.training_module_time_field.hours')\
                               + ' %M ' + I18n.t('users.training_module_time_field.minutes')\
                               + ' %S ' + I18n.t('users.training_module_time_field.seconds'))
    end
  end
end
