class AddFaq < ActiveRecord::Migration[6.0]
  def change
    create_table :faqs do |t|
      t.timestamps
      t.string :title, null: false
      t.text :content
    end
  end
end
