class AddEmailTemplateToSurveyAssignment < ActiveRecord::Migration[4.2]
  def change
    add_column :survey_assignments, :email_template, :string
  end
end
