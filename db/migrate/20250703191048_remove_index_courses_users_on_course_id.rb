class RemoveIndexCoursesUsersOnCourseId < ActiveRecord::Migration[7.0]
  def change
    remove_index :courses_users, name: "index_courses_users_on_course_id"
  end
end