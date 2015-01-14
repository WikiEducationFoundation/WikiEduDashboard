class AddNamespaceToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :namespace, :integer
  end
end
