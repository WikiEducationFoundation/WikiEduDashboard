class AddAverageViewsAndAverageViewsUpdatedAtToArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :average_views, :float
    add_column :articles, :average_views_updated_at, :date
  end
end
