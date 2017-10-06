class AddNoteToSurveyAssignment < ActiveRecord::Migration[4.2]
  def change
    add_column :survey_assignments, :notes, :text
  end
end
