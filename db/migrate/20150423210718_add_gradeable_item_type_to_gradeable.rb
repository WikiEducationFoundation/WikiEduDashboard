class AddGradeableItemTypeToGradeable < ActiveRecord::Migration
  def change
    add_column :gradeables, :gradeable_item_type, :string
  end
end
