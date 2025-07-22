class CreateSurveyAssignments < ActiveRecord::Migration[4.2]
  def change
    create_table :survey_assignments do |t|
      t.integer :courses_user_role
      t.timestamps null: false
      t.integer :send_date_days
      t.belongs_to :survey, index: true
      t.boolean :send_before, default: true
      t.string :send_date_relative_to #course_endm course_start
    end

    create_table :cohorts_survey_assignments, id: false do |t|
      t.belongs_to :survey_assignment, index: true
      t.belongs_to :cohort, index: true
    end
  end
end
