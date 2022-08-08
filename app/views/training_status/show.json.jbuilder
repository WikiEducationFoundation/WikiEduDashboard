# frozen_string_literal: true

json.course do
  json.training_modules @assigned_training_modules do |training_module|
    training_progress_manager = TrainingProgressManager.new(@user, training_module)
    due_date_manager = TrainingModuleDueDateManager.new(
      course: @course,
      training_module:,
      user: @user
    )

    json.id training_module.id
    json.kind training_module.kind
    json.status training_progress_manager.status
    json.module_name training_module.name

    json.overdue due_date_manager.overdue?
    json.due_date due_date_manager.computed_due_date
    json.deadline_status due_date_manager.deadline_status

    json.sandbox_url due_date_manager.sandbox_url

    json.completion_date training_progress_manager.completion_date
    json.completion_time training_progress_manager.completion_time
  end
end
