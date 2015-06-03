json.weeks course.weeks do |week|
  json.(week, :id, :title)
  json.blocks week.blocks do |block|
    json.(block, :id, :kind, :content, :week_id, :gradeable_id, :title, :order, :due_date)
    unless json.gradeable.nil?
      json.gradeable block.gradeable, :id, :title, :points, :gradeable_item_type
    end
  end
end
