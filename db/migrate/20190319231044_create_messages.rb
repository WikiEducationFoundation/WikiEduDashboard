class CreateMessages < ActiveRecord::Migration[5.2]
  def change
    create_table :messages do |t|
      t.integer :kind, default: 0, limit: 1
      t.integer :sender_id
      t.references :ticket
      t.boolean :read, default: false, null: false
      t.text :content, limit: 16_000, null: false

      t.timestamps
    end

    add_foreign_key :messages, :users, column: :sender_id
  end
end
