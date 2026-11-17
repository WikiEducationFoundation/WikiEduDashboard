# frozen_string_literal: true

# Scholars & Scientists application forms (Wiki Education Dashboard only). A
# course that takes applications has one form: whether it is open, a
# staff-written intro, and an ordered list of Rapidfire question groups — a base
# group shared by every course, then any narrower groups for a course theme or a
# single course. The groups are ordinary Rapidfire question groups, authored in
# the survey admin.
class CreateCourseApplicationForms < ActiveRecord::Migration[8.1]
  def change
    create_table :course_application_forms do |t|
      t.integer :course_id, null: false
      t.boolean :open, null: false, default: false
      t.text :intro
      # Ordered Rapidfire question group ids, as a serialized array. A
      # handful of rows ever exist, so "which forms use group X" is answered
      # by reading them all rather than through a join table.
      t.text :question_group_ids
      t.timestamps
      t.index :course_id, unique: true
    end
    add_foreign_key :course_application_forms, :courses, on_delete: :cascade
  end
end
