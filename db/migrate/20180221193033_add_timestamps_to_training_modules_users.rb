class AddTimestampsToTrainingModulesUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :training_modules_users, :created_at, :datetime
    add_column :training_modules_users, :updated_at, :datetime
  end
end
