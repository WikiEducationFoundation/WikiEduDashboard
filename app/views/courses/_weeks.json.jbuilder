json.weeks course.weeks.eager_load(blocks: [:gradeable]) do |week|
  json.call(week, :id, :title, :order)
  json.blocks week.blocks do |block|
    json.call(block, :id, :kind, :content, :week_id,
              :gradeable_id, :title, :order, :due_date,
              :training_module_id)
    unless block.gradeable.nil?
      json.gradeable block.gradeable, :id, :title, :points,
                     :gradeable_item_type, :gradeable_item_id
    end
    if block.training_module.present?
      json.training_module block.training_module, :id, :name, :slug, :intro
    end
  end
end
