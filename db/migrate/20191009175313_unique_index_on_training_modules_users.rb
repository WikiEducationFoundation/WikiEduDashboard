class UniqueIndexOnTrainingModulesUsers < ActiveRecord::Migration[6.0]
  def change
    remove_index :training_modules_users, [:user_id, :training_module_id]
    add_index :training_modules_users, [:user_id, :training_module_id], unique: true
  end
end
