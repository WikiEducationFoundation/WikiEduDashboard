class AddTrackedToArticles < ActiveRecord::Migration[5.2]
  def change
    add_column :articles, :tracked, :bool, :default => true
  end
end
