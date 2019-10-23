class AddFlagsToTrainingModulesUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :training_modules_users, :flags, :text
  end
end
