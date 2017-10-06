class RenameCoursesUsersColumn < ActiveRecord::Migration[4.2]
  def change
    rename_column :courses_users, :character_count, :character_sum
  end
end
