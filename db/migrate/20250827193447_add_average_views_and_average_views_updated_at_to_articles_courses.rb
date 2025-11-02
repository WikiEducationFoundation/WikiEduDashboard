class AddAverageViewsAndAverageViewsUpdatedAtToArticlesCourses < ActiveRecord::Migration[7.0]
  def change
     unless column_exists?(:articles_courses, :average_views)
      add_column :articles_courses, :average_views, :float
     end

     unless column_exists?(:articles_courses, :average_views_updated_at)
      add_column :articles_courses, :average_views_updated_at, :date
     end
  end
end
