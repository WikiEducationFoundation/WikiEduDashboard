class CreateTagTable < ActiveRecord::Migration[4.2]
  def change
    create_table :tags do |t|
      t.integer :course_id
      t.string :tag
      t.string :key
      t.timestamps
    end

    add_index :tags, [:course_id, :key], :unique => true
  end
end
