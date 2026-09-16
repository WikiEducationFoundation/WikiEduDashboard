# frozen_string_literal: true

# Privacy mode for Wiki Ed courses. A course in privacy mode stores obfuscated
# stand-ins in `courses.title` and `courses.school` — so the slug, the on-wiki
# course page, and every serialization site are anonymous by construction — and
# the real values live here, where only admins can read them.
#
# Deliberately a separate table rather than extra columns on `courses` or keys
# in `courses.flags`: both of those are serialized into the public course JSON,
# so a future `json.call(course, ...)` could leak them by accident.
class CreateConfidentialCourseDetails < ActiveRecord::Migration[8.1]
  def change
    create_table :confidential_course_details, charset: 'utf8mb4',
                                               collation: 'utf8mb4_unicode_ci' do |t|
      t.integer :course_id, null: false
      t.integer :sequence, null: false
      t.string :real_title
      t.string :real_school
      t.timestamps
    end
    # `sequence` is unique because the obfuscated title is built from it, and
    # that title is what makes the course slug unique.
    add_index :confidential_course_details, :course_id, unique: true
    add_index :confidential_course_details, :sequence, unique: true
  end
end
