class CreateTickets < ActiveRecord::Migration[5.2]
  def change
    create_table :tickets do |t|
      t.references :course
      t.references :alert
      t.references :user, :owner, index: true
      t.integer :status, default: 0, limit: 1

      t.timestamps
    end
  end
end
