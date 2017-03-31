class CreateBlocks < ActiveRecord::Migration[4.2]
  def change
    create_table :blocks do |t|
      t.integer :type
      t.string :content
      t.integer :weekday

      t.integer :week_id
      t.integer :gradeable_id

      t.timestamps
    end
  end
end
