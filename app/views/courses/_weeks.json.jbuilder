json.weeks course.weeks.eager_load(blocks: [:gradeable]) do |week|
  json.call(week, :id, :title, :order)
  json.blocks week.blocks do |block|
    json.call(block, :id, :kind, :content, :week_id,
              :gradeable_id, :title, :order, :due_date,
              :training_module_ids)
    unless block.gradeable.nil?
      json.gradeable block.gradeable, :id, :title, :points,
                     :gradeable_item_type, :gradeable_item_id
    end
    if block.training_modules.any?
      json.training_modules block.training_modules do |tm|
        progress_manager = TrainingProgressManager.new(current_user, tm)
        json.call(tm, :slug, :id, :name)
        json.module_progress progress_manager.module_progress
      end
    end
  end
end
