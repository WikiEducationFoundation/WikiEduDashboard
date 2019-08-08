class AddTrackedToArticlesCourses < ActiveRecord::Migration[5.2]
  def change
    add_column :articles_courses, :tracked, :bool, :default => true
  end
end
