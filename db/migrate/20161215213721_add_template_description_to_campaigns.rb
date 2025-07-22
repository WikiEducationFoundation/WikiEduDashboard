class AddTemplateDescriptionToCampaigns < ActiveRecord::Migration[5.0]
  def change
    add_column :campaigns, :template_description, :text
  end
end
