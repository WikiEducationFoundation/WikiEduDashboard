class AddReferencesCountToArticlesCourses < ActiveRecord::Migration[5.2]
  def change
    add_column :articles_courses, :references_count, :integer, default: 0
  end
end
