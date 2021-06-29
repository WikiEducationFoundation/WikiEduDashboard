class RemoveCategoryIndex < ActiveRecord::Migration[6.1]
  def change
    remove_index :categories, [:wiki_id, :name, :depth]
  end
end
