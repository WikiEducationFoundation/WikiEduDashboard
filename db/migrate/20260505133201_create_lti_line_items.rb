# frozen_string_literal: true

# Maps a Dashboard gradable unit to a Canvas (or other LMS) gradebook line
# item managed by LTIAAS.
#
# `gradable_type='Block'` covers per-block gradebook columns (when an
# LtiCourseBinding's gradebook_granularity is 'per_block').
# `gradable_type='TrainingProgress'` is a sentinel used in 'lumped' mode for
# the single rolled-up "Wikipedia trainings" column; gradable_id is null.
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
    add_index :lti_line_items, %i[lti_course_binding_id gradable_type gradable_id],
              unique: true, name: 'index_lti_line_items_on_binding_and_gradable'
    add_index :lti_line_items, %i[lti_course_binding_id lineitem_id], unique: true,
              length: { lineitem_id: 191 }, name: 'index_lti_line_items_on_binding_and_lineitem'
  end

  def add_columns(table)
    table.references :lti_course_binding, null: false,
                                          foreign_key: { on_delete: :cascade }, type: :integer
    table.string :gradable_type, null: false
    table.integer :gradable_id
    table.string :lineitem_id, null: false, limit: 512
    table.string :label
    table.decimal :score_maximum, precision: 10, scale: 4, null: false, default: 1.0
    table.string :last_pushed_signature
    table.datetime :archived_at
  end
end
