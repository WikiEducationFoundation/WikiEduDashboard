class AddWikiTitleNamespaceIndexToArticles < ActiveRecord::Migration[5.0]
  def change
    add_index :articles, [:namespace, :wiki_id, :title]
  end
end
