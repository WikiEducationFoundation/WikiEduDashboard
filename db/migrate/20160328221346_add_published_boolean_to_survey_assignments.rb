class AddPublishedBooleanToSurveyAssignments < ActiveRecord::Migration[4.2]
  def change
    add_column :survey_assignments, :published, :boolean, default: false
  end
end
