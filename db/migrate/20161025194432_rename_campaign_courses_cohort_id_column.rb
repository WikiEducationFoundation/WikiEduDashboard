class RenameCampaignCoursesCohortIdColumn < ActiveRecord::Migration[5.0]
  def change
    rename_column :campaigns_courses, :cohort_id, :campaign_id
  end
end
