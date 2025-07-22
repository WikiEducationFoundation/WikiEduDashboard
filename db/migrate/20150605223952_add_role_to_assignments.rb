class AddRoleToAssignments < ActiveRecord::Migration[4.2]
  def change
    add_column :assignments, :role, :integer
    drop_table :assignments_users
  end
end
