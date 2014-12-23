class AddViewsUpdatedAtToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :views_updated_at, :date
  end
end
