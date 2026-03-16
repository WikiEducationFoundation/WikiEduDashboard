class AddDefaultLanguageToCampaigns < ActiveRecord::Migration[7.0]
  def change
    add_column :campaigns, :default_language, :string
  end
end
