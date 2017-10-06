class AddColumnsToJoinTables < ActiveRecord::Migration[4.2]
  def change
    add_column :articles_courses, :article_id, :integer
    add_column :articles_courses, :course_id, :integer
    add_column :articles_courses, :view_count, :integer

    add_column :courses_users, :course_id, :integer
    add_column :courses_users, :user_id, :integer
    add_column :courses_users, :character_count, :integer
  end
end
