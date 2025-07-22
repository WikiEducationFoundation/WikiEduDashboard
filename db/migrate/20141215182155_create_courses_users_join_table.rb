class CreateCoursesUsersJoinTable < ActiveRecord::Migration[4.2]
  def change
    create_join_table :courses, :users do |t|
      # t.index [:course_id, :user_id]
      # t.index [:user_id, :course_id]
    end
  end
end
