class AddCustomEmailToSurveyAssignments < ActiveRecord::Migration
  def change
    add_column :survey_assignments, :custom_email, :text
  end
end
