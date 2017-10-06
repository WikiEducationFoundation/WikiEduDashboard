class CreateRevisions < ActiveRecord::Migration[4.2]
  def change
    create_table :revisions do |t|
      t.date :date
      t.integer :bytes

      t.timestamps
    end
  end
end
