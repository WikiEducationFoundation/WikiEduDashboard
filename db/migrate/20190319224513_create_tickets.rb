class CreateTickets < ActiveRecord::Migration[5.2]
  def change
    create_table :tickets do |t|
      t.references :course
      t.integer :owner_id, index: true
      t.integer :status, default: 0, limit: 1

      t.timestamps
    end

    add_foreign_key :tickets, :users, column: :owner_id
  end
end
