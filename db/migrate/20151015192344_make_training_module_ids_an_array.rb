class MakeTrainingModuleIdsAnArray < ActiveRecord::Migration
  def change
    remove_column :blocks, :training_module_id
    add_column :blocks, :training_module_ids, :text
  end
end
