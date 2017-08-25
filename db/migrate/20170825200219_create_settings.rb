class CreateSettings < ActiveRecord::Migration[5.1]
  def change
    create_table :settings do |t|
      t.string :key
      t.text :value
      t.timestamps
    end
    add_index :settings, :key, unique: true
  end
end
