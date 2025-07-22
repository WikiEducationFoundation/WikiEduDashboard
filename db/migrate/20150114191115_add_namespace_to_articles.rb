class AddNamespaceToArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :namespace, :integer
  end
end
