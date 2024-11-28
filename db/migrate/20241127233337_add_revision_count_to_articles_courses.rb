class AddRevisionCountToArticlesCourses < ActiveRecord::Migration[7.0]
  def change
    add_column :articles_courses, :revision_count, :integer, default: 0
  end
end
