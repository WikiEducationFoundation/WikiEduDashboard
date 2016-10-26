class RenameCohortsSurveyAssignmentsTableToCampaignsSurveyAssignments < ActiveRecord::Migration[5.0]
  def change
    rename_table :cohorts_survey_assignments, :campaigns_survey_assignments
  end
end
