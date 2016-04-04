class AddNoteToSurveyAssignment < ActiveRecord::Migration
  def change
    add_column :survey_assignments, :notes, :text
  end
end
