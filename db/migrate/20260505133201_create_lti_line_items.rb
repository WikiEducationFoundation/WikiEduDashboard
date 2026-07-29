# frozen_string_literal: true

# Maps a Dashboard gradable unit to a Canvas (or other LMS) gradebook line
# item managed by LTIAAS.
#
# `gradable_type='Block'` covers per-block gradebook columns.
# `gradable_type='TrainingProgress'` and `'WikipediaSetup'` are sentinels for the
# rolled-up trainings column and the "connected a Wikipedia account" indicator;
# both carry a null `gradable_id`.
#
# That null is why `gradable_key` exists. MySQL treats NULLs as distinct in a
# unique index, so a (binding, gradable_type, gradable_id) index constrains the
# Block rows but not the sentinels — and a model validation can't close the gap,
# because two concurrent creates for one gradable can both pass validation and
# then insert different `lineitem_id`s, which is reachable from a replayed
# deep-link submission. `gradable_key` is a stored generated column that folds
# the null away ("Block:42", "TrainingProgress"), so one unique index per binding
# enforces the invariant for every row type. Same device as
# `articles.index_hash`.
#
# `canvas_assignment_id` records the Canvas-side assignment id so an
# `assignment_view` launch (which carries `$Canvas.assignment.id` in its custom
# claim) can be routed back to the matching line item. Nullable: it's backfilled
# by the first such launch, and the sentinel columns never get one. Stored as a
# string because Canvas ids can be globally prefixed for cross-shard installs.
#
# `archived_at` soft-archives line items whose underlying gradable went
# away in the Dashboard timeline. We never hard-delete the LTIAAS line item
# because that destroys gradebook column data in Canvas.
class CreateLtiLineItems < ActiveRecord::Migration[8.1]
  def change
    create_table :lti_line_items, id: :integer do |t|
      add_columns(t)
      t.timestamps
    end
    add_index :lti_line_items, %i[lti_course_binding_id gradable_key],
              unique: true, name: 'index_lti_line_items_on_binding_and_gradable_key'
    add_index :lti_line_items, %i[lti_course_binding_id lineitem_id], unique: true,
              length: { lineitem_id: 191 }, name: 'index_lti_line_items_on_binding_and_lineitem'
    add_index :lti_line_items, %i[lti_course_binding_id canvas_assignment_id], unique: true,
              name: 'index_lti_line_items_on_binding_and_canvas_assignment'
  end

  def add_columns(table)
    table.references :lti_course_binding, null: false,
                                          foreign_key: { on_delete: :cascade }, type: :integer
    table.string :gradable_type, null: false
    table.integer :gradable_id
    table.virtual :gradable_key, type: :string, stored: true,
                                 as: "concat(`gradable_type`, ':', ifnull(`gradable_id`, ''))"
    table.string :lineitem_id, null: false, limit: 512
    table.string :label
    table.decimal :score_maximum, precision: 10, scale: 4, null: false, default: 1.0
    table.datetime :archived_at
    table.string :canvas_assignment_id
  end
end
