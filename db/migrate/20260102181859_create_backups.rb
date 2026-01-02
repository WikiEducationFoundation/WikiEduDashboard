class CreateBackups < ActiveRecord::Migration[7.0]
  def change
    create_table :backups do |t|
      t.datetime :scheduled_at
      t.datetime :start
      t.datetime :end
      t.string :status

      t.timestamps
    end
  end
end
