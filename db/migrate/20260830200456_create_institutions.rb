class CreateInstitutions < ActiveRecord::Migration[8.1]
  def change
    create_table :institutions do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :institutions, :name, unique: true
  end
end
