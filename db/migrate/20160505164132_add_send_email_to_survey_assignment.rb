class AddSendEmailToSurveyAssignment < ActiveRecord::Migration
  def change
    add_column :survey_assignments, :send_email, :boolean
  end
end
