class AddEmailTemplateToSurveyAssignment < ActiveRecord::Migration
  def change
    add_column :survey_assignments, :email_template, :string
  end
end
