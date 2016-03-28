class AddPublishedBooleanToSurveyAssignments < ActiveRecord::Migration
  def change
    add_column :survey_assignments, :published, :boolean, default: false
  end
end
