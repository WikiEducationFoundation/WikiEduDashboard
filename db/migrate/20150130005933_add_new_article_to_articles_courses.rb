class AddNewArticleToArticlesCourses < ActiveRecord::Migration
  def change
    add_column :articles_courses, :new_article, :boolean, :default => false
  end
end
