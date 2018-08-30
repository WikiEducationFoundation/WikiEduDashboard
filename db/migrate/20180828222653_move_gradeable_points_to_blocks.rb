class MoveGradeablePointsToBlocks < ActiveRecord::Migration[5.2]
  # This data migration has already been run in the production servers,
  # in preparation for removing the Gradeable model and relations.
  # It won't run after the remove of Gradeable is complete.
  def up
    # Block.where.not(gradeable_id: nil).each do |block|
    #   block.update(points: block.gradeable&.points)
    # end
  end
  def down
  end
end
