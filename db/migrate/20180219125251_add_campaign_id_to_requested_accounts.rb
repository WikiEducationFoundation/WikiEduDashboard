class AddCampaignIdToRequestedAccounts < ActiveRecord::Migration[5.1]
  def change
    add_column :requested_accounts, :campaign_id, :integer
  end
end
