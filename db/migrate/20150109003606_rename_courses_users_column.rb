class RenameCoursesUsersColumn < ActiveRecord::Migration
  def change
    rename_column :courses_users, :character_count, :character_sum
  end
end
