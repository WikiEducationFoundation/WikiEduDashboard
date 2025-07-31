class AddIndexToCampaignsCoursesOnCampaignId < ActiveRecord::Migration[7.0]
  def change
    add_index :campaigns_courses, :campaign_id, name: "index_campaigns_courses_on_campaign_id"
  end
end
