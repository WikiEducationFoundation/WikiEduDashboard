# frozen_string_literal: true

# Per-student retention metrics for Scholars & Scientists (FellowsCohort)
# courses, computed from the live usercontribs API by RetentionStudentStats and
# stored so the report card page never has to fetch them on request.
class CreateRetentionStats < ActiveRecord::Migration[8.1]
  def change
    create_table :retention_stats, charset: 'utf8mb4', collation: 'utf8mb4_unicode_ci' do |t|
      t.integer :course_id, null: false
      t.integer :user_id, null: false
      t.integer :sessions_during, null: false, default: 0
      t.integer :days_to_return
      t.integer :sessions_after
      t.integer :edits_60_90
      t.integer :prior_edit_count, null: false, default: 0
      t.boolean :long_term_wikipedian, null: false, default: false
      t.integer :prior_course_count, null: false, default: 0
      t.datetime :computed_at, null: false
      t.timestamps
    end
    add_index :retention_stats, %i[course_id user_id], unique: true
  end
end
