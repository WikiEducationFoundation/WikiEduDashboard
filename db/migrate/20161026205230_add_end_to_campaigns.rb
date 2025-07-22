class AddEndToCampaigns < ActiveRecord::Migration[5.0]
  def change
    add_column :campaigns, :end, :datetime
  end
end
