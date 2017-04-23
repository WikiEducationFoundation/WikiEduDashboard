class AddIndexesToCoursesUsers < ActiveRecord::Migration[5.0]
  def change
    add_index :courses_users, :user_id
    add_index :courses_users, :course_id
  end
end
