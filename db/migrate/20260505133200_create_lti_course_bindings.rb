# frozen_string_literal: true

# Persists the 1:1 binding between a Canvas (or other LMS) course and a
# Dashboard Course. Keyed on the LMS course — (lms_id, lms_context_id) — so
# every launch from that course, from any placement, resolves to one row; the
# resource link is a snapshot of the launch that created/refreshed the row, not
# part of its identity. `course_id` is nullable and uniquely indexed: nil between
# the first launch and the instructor's setup choice, and a Dashboard course
# backs at most one LMS course.
#
# `ltiaas_service_credentials` holds the service-auth credentials used by
# background jobs (NRPS roster sync, AGS grade passback). Stored in plain text,
# like every other external credential this app persists — users.wiki_token /
# users.wiki_secret are Wikipedia OAuth credentials in the same shape. Doing
# better means standing up Active Record encryption key management across both
# production deployments for the whole credential store; tracked as an app-wide
# follow-up in docs/canvas_integration_todos.md rather than promised here.
class CreateLtiCourseBindings < ActiveRecord::Migration[8.1]
  def change
    # Collation pinned to utf8mb4_unicode_ci to match every other table in the
    # schema. Modern MariaDB defaults to utf8mb4_uca1400_ai_ci, which MySQL
    # doesn't recognize — so without this a forward `db:migrate` re-dumps
    # schema.rb with a collation that then breaks `db:schema:load` on CI.
    create_table :lti_course_bindings, id: :integer,
                                           options: 'CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci' do |t|
      add_columns(t)
      t.timestamps
    end
    add_index :lti_course_bindings, %i[lms_id lms_context_id],
              unique: true, name: 'index_lti_course_bindings_on_lms_context'
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
    table.string :lms_context_title
    table.string :lms_platform_url
    table.text :ltiaas_service_credentials
    table.string :nrps_url
    table.string :ags_lineitems_url
    table.datetime :last_roster_sync_at
    table.text :last_roster_sync_error
    table.datetime :last_grade_sync_at
    table.text :last_grade_sync_error
    # Dispatcher bookkeeping, distinct from last_grade_sync_at (which only a
    # *completed* sync advances): stamped whenever the periodic dispatcher
    # enqueues the binding, so a binding whose syncs always abort still moves
    # to the back of the queue instead of starving the healthy ones.
    table.datetime :last_grade_sync_attempt_at
  end
end
