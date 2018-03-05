class CreateTrainingSlide < ActiveRecord::Migration[5.1]
  def change
    create_table :training_slides do |t|
      t.string :title
      t.string :title_prefix
      t.string :summary
      t.string :button_text
      t.string :wiki_page
      t.text :assessment, limit: 16_000
      t.text :content, limit: 16_000
      t.text :translations, limit: 2_000_000
      t.string :slug, index: { unique: true }
      t.timestamps null: false
    end
  end
end
