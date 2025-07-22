class AddViewsUpdatedAtToArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :views_updated_at, :date
  end
end
