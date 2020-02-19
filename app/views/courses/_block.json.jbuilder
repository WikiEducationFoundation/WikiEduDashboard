# frozen_string_literal: true

user ||= current_user
json.call(block, :id, :kind, :content, :week_id, :title,
          :order, :due_date, :training_module_ids, :points)
if block.training_modules.any?
  json.training_modules block.training_modules do |tm|
    # The available training modules may change over time, especially on
    # Programs & Events Dashboard where wiki trainings are enabled.
    # For modules that aren't found, simply skip sending info.
    next unless tm
    due_date_manager = TrainingModuleDueDateManager.new(
      course: course,
      training_module: tm,
      user: user
    )
    json.call(tm, :slug, :id, :name, :kind)
    json.module_progress due_date_manager.module_progress
    json.due_date due_date_manager.computed_due_date.strftime('%Y/%m/%d')
    json.overdue due_date_manager.overdue?
    json.deadline_status due_date_manager.deadline_status
    json.flags due_date_manager.flags
    json.block_id block.id
  end
end
