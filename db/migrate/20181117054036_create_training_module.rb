class CreateTrainingModule < ActiveRecord::Migration[5.2]
  def change
    create_table :training_modules do |t|
      t.string :name
      t.string :estimated_ttc
      t.string :wiki_page
      t.string :slug, index: { unique: true }
      t.text :slide_slugs, limit: 16_000
      t.text :description, limit: 16_000
      t.text :translations, limit: 2_000_000
      t.timestamps null: false
    end
  end
end
