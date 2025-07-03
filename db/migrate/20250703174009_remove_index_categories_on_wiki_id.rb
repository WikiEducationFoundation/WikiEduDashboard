class RemoveIndexCategoriesOnWikiId < ActiveRecord::Migration[7.0]
  def change
    remove_index :categories, name: "index_categories_on_wiki_id"
  end
end
