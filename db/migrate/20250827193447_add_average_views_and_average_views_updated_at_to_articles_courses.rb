class AddAverageViewsAndAverageViewsUpdatedAtToArticlesCourses < ActiveRecord::Migration[7.0]
  def change
    add_column :articles_courses, :average_views, :float
    add_column :articles_courses, :average_views_updated_at, :date
  end
end
