class RenameCohortsTableToCampaigns < ActiveRecord::Migration[5.0]
  def change
    rename_table :cohorts, :campaigns
  end
end
