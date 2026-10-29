# frozen_string_literal: true

# One application per applicant per course. The answers are Rapidfire answer
# groups — one per question group on the course's form — linked back here by
# `rapidfire_answer_groups.course_application_id`.
class CreateCourseApplications < ActiveRecord::Migration[8.1]
  def change
    create_table :course_applications do |t|
      t.integer :course_id, null: false
      t.integer :user_id, null: false
      t.integer :status, null: false, default: 0
      t.integer :decided_by_id
      t.datetime :decided_at
      t.text :staff_notes
      t.timestamps
      t.index %i[course_id user_id], unique: true
      t.index :user_id
    end

    add_column :rapidfire_answer_groups, :course_application_id, :bigint
    add_index :rapidfire_answer_groups, :course_application_id
  end
end
