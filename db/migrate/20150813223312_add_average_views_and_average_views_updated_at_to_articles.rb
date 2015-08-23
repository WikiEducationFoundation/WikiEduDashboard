class AddAverageViewsAndAverageViewsUpdatedAtToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :average_views, :float
    add_column :articles, :average_views_updated_at, :date
  end
end
