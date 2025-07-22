class UniqueIndexOnCoursesUsers < ActiveRecord::Migration[5.1]
  def change
    add_index :courses_users, [:course_id, :user_id, :role], unique: true
  end
end
