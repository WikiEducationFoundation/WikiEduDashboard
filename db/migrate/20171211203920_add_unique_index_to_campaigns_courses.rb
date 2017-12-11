class AddUniqueIndexToCampaignsCourses < ActiveRecord::Migration[5.1]
  def change
    add_index :campaigns_courses, [:course_id, :campaign_id], unique: true
  end
end
