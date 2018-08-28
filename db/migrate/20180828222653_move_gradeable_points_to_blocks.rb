class MoveGradeablePointsToBlocks < ActiveRecord::Migration[5.2]
  def up
    Block.where.not(gradeable_id: nil).each do |block|
      block.update(points: block.gradeable&.points)
    end
  end
  def down
  end
end
