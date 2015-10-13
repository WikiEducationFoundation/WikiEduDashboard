class AddTrainingModuleIdToBlocks < ActiveRecord::Migration
  def change
    add_column :blocks, :training_module_id, :integer
  end
end
