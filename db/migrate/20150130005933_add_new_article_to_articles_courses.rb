class AddNewArticleToArticlesCourses < ActiveRecord::Migration[4.2]
  def change
    add_column :articles_courses, :new_article, :boolean, :default => false
  end
end
