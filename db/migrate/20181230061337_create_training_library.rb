class CreateTrainingLibrary < ActiveRecord::Migration[5.2]
  def change
    create_table :training_libraries do |t|
      t.string :name
      t.string :wiki_page
      t.string :slug, index: { unique: true }
      t.text :introduction, limit: 16_000
      t.text :categories, limit: 2_000_000
      t.text :translations, limit: 2_000_000
      t.boolean :exclude_from_index, default: false
      t.timestamps null: false
    end
  end
end
