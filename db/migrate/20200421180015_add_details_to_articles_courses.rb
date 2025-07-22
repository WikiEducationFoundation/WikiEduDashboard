class AddDetailsToArticlesCourses < ActiveRecord::Migration[6.0]
  def change
    add_column :articles_courses, :user_ids, :text
  end
end
