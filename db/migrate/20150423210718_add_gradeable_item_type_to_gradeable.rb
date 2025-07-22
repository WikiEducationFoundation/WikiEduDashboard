class AddGradeableItemTypeToGradeable < ActiveRecord::Migration[4.2]
  def change
    add_column :gradeables, :gradeable_item_type, :string
  end
end
