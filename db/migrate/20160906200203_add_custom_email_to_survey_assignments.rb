class AddCustomEmailToSurveyAssignments < ActiveRecord::Migration[4.2]
  def change
    add_column :survey_assignments, :custom_email, :text
  end
end
