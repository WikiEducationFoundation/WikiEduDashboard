# frozen_string_literal: true
# This migration comes from ticket_dispenser (originally 20190322210241)

class CreateMessage < ActiveRecord::Migration[5.2]
  def change
    create_table :ticket_dispenser_messages do |t|
      t.integer :kind, default: 0, limit: 1
      t.integer :sender_id
      t.references :ticket
      t.boolean :read, default: false, null: false
      t.text :content, limit: 16_000, null: false

      t.timestamps
    end
  end
end
