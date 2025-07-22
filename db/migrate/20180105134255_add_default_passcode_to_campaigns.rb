class AddDefaultPasscodeToCampaigns < ActiveRecord::Migration[5.1]
  def change
    add_column :campaigns, :default_passcode, :string
  end
end
