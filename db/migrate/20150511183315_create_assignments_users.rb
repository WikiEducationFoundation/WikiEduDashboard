class CreateAssignmentsUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :assignments_users do |t|
      t.integer :assignment_id
      t.integer :user_id
      t.timestamps
    end
  end
end
