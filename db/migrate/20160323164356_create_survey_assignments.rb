class CreateSurveyAssignments < ActiveRecord::Migration
  def change
    create_table :survey_assignments do |t|
      t.integer :courses_user_role
      t.timestamps null: false
      t.integer :send_date_days
      t.boolean :send_before, default: true
      t.string :send_date_relative_to #course_endm course_start
    end

    create_table :cohorts_survey_assignments, id: false do |t|
      t.belongs_to :survey_assignment, index: true
      t.belongs_to :cohort, index: true
    end

    create_table :survey_assignments_surveys, id: false do |t|
      t.belongs_to :survey_assignment, index: true
      t.belongs_to :survey, index: true
    end
  end
end
