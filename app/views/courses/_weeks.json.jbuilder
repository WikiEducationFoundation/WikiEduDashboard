json.weeks course.weeks do |week|
  json.(week, :id, :title)
  json.blocks week.blocks do |block|
    json.(block, :id, :kind, :content, :week_id, :gradeable_id, :title, :order, :duration)
    unless block.gradeable.nil?
      json.gradeable block.gradeable, :id, :title, :points, :gradeable_item_type, :gradeable_item_id
    end
  end
end
