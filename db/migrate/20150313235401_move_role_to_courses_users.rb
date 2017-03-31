class MoveRoleToCoursesUsers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :courses_users, :role, :integer, :default => 0
    execute "UPDATE courses_users cu, users u SET cu.role = u.role WHERE cu.user_id = u.id"
    remove_column :users, :role
  end

  def self.down
    add_column :users, :role, :integer, :default => 0
    execute "UPDATE courses_users cu, users u SET u.role = cu.role WHERE u.id = cu.user_id"
    remove_column :courses_users, :role
  end
end
