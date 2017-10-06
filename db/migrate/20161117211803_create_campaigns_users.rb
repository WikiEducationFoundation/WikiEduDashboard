class CreateCampaignsUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :campaigns_users do |t|
      t.references :campaign
      t.references :user
      t.integer :role, :default => 0

      t.timestamps
    end
  end
end
