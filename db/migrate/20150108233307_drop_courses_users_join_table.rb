class DropCoursesUsersJoinTable < ActiveRecord::Migration
  def change
    drop_join_table :courses, :users
  end
end
