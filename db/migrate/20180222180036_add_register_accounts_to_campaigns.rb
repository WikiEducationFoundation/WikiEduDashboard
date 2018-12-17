class AddRegisterAccountsToCampaigns < ActiveRecord::Migration[5.1]
  def change
    add_column :campaigns, :register_accounts, :boolean, default: false
  end
end
