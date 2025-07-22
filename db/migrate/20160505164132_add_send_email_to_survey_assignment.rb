class AddSendEmailToSurveyAssignment < ActiveRecord::Migration[4.2]
  def change
    add_column :survey_assignments, :send_email, :boolean
  end
end
