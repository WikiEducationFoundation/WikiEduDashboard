class AddDescriptionToCampaigns < ActiveRecord::Migration[5.0]
  def change
    add_column :campaigns, :description, :text
  end
end
