class AddIndexToTrainingModulesUsers < ActiveRecord::Migration[5.0]
  def change
    add_index :training_modules_users, [:user_id, :training_module_id]
  end
end
