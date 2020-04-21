class AddDetailsToArticlesCourses < ActiveRecord::Migration[6.0]
  def change
    add_column :articles_courses, :details, :text
  end
end
