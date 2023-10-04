class CreateWikipediaCategoryMembers < ActiveRecord::Migration[7.0]
  def change
    create_table :wikipedia_category_members do |t|
      t.text :category_member

      t.timestamps
    end
  end
end
