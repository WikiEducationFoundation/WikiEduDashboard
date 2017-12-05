class CreateCategories < ActiveRecord::Migration[5.1]
  def change
    create_table :categories do |t|
      t.integer :wiki_id, index: true
      t.text :article_titles, limit: 16.megabytes - 1
      t.string :name, index: true
      t.integer :depth, default: 0
      t.timestamps
    end
  end
end
