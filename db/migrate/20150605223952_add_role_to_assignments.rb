class AddRoleToAssignments < ActiveRecord::Migration
  def change
    add_column :assignments, :role, :integer
    drop_table :assignments_users
  end
end
