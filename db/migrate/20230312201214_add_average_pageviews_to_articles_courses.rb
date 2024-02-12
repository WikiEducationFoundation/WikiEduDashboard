class AddAveragePageviewsToArticlesCourses < ActiveRecord::Migration[7.0]
  def change
    add_column :articles_courses, :average_pageviews, :integer, :default => 0
  end
end
