class AddCategoryIndex < ActiveRecord::Migration[6.1]
  def change
    add_index :categories, [:wiki_id, :name, :depth, :source], unique: true
  end
end
