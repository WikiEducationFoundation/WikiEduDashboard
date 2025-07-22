class AddStartToCampaigns < ActiveRecord::Migration[5.0]
  def change
    add_column :campaigns, :start, :datetime
  end
end
