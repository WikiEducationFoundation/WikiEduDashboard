class FixJoinColumnNames < ActiveRecord::Migration
  def change
    rename_table :CourseIDs_UserIDs, :courses_users
    rename_column :courses_users, :course_id_id, :course_id
    rename_column :courses_users, :user_id_id, :user_id
  end
end
