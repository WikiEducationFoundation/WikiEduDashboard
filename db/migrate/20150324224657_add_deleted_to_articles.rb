class AddDeletedToArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :deleted, :boolean, :default => false
  end
end
