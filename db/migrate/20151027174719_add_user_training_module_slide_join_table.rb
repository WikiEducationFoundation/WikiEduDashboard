class AddUserTrainingModuleSlideJoinTable < ActiveRecord::Migration[4.2]
  def change
    create_table :training_modules_users do |t|
      t.integer :user_id
      t.integer :training_module_id
      t.string :last_slide_completed
      t.datetime :completed_at
    end
  end
end
