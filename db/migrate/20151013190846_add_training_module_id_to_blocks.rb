class AddTrainingModuleIdToBlocks < ActiveRecord::Migration[4.2]
  def change
    add_column :blocks, :training_module_id, :integer
  end
end
