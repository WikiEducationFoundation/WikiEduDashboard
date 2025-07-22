class RemoveGradeableIdFromBlock < ActiveRecord::Migration[5.2]
  def change
    remove_column :blocks, :gradeable_id, :integer
  end
end
