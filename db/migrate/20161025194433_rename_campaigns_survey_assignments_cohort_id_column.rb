class RenameCampaignsSurveyAssignmentsCohortIdColumn < ActiveRecord::Migration[5.0]
  def change
    rename_column :campaigns_survey_assignments, :cohort_id, :campaign_id
  end
end
