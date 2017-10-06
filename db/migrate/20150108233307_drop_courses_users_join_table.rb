class DropCoursesUsersJoinTable < ActiveRecord::Migration[4.2]
  def change
    drop_join_table :courses, :users
  end
end
