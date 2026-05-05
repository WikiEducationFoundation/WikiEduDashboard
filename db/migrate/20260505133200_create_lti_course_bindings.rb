# frozen_string_literal: true

# Persists the 1:1 binding between a Canvas (or other LMS) course/placement
# and a Dashboard Course. One row per LMS resource link.
#
# `ltiaas_service_credentials` is reserved for the service-auth credentials
# used by background jobs (NRPS roster sync, AGS grade passback). It is
# unused in PR 1 and will be encrypted before population in a later PR.
class CreateLtiCourseBindings < ActiveRecord::Migration[8.1]
  def change
    create_table :lti_course_bindings, id: :integer do |t|
      add_columns(t)
      t.timestamps
    end
    add_index :lti_course_bindings, %i[lms_id lms_context_id lms_resource_link_id],
              unique: true, name: 'index_lti_course_bindings_on_lms_identity'
    add_index :lti_course_bindings, :course_id, unique: true,
              name: 'index_lti_course_bindings_on_course_id_unique'
  end

  def add_columns(table)
    table.references :course, null: true, foreign_key: { on_delete: :cascade },
                              type: :integer, index: false
    table.string :lms_id, null: false
    table.string :lms_family
    table.string :lms_context_id, null: false
    table.string :lms_resource_link_id, null: false
    table.text :ltiaas_service_credentials
    table.string :nrps_url
    table.string :ags_lineitems_url
    table.string :gradebook_granularity, null: false, default: 'lumped'
    table.datetime :last_roster_sync_at
    table.datetime :last_grade_sync_at
    table.text :last_grade_sync_error
  end
end
