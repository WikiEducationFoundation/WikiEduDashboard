# frozen_string_literal: true
# This migration comes from ticket_dispenser (originally 20190322210232)

class CreateTicket < ActiveRecord::Migration[5.2]
  def change
    create_table :ticket_dispenser_tickets do |t|
      t.references :project
      t.integer :owner_id, index: true
      t.integer :status, default: 0, limit: 1

      t.timestamps
    end
  end
end
