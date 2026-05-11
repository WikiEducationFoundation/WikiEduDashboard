# frozen_string_literal: true

# Per-(line item, student) score POST dedup signatures. SyncLtiGrades
# computes a signature (sha1 of score + comment) for each push and
# compares it against the stored row before POSTing; matching means no
# state change since last push so the POST is skipped. This makes the
# 30-min cron a no-op when nothing has changed, instead of re-POSTing
# every (student × line item) pair every cycle.
#
# Also drops `last_pushed_signature` from `lti_line_items` — that column
# was reserved for this feature but is the wrong shape (per-line-item,
# not per-(line item, student)) and was never read or written.
class CreateLtiScoreSignatures < ActiveRecord::Migration[8.1]
  def change
    # FK column types match each referenced table's PK type:
    # lti_line_items.id is int; lti_contexts.id is bigint (the default).
    create_table :lti_score_signatures, id: :integer do |t|
      t.references :lti_line_item, null: false,
                                   foreign_key: { on_delete: :cascade }, type: :integer
      t.references :lti_context, null: false,
                                 foreign_key: { on_delete: :cascade }
      t.string :signature, null: false
      t.datetime :last_pushed_at, null: false
      t.timestamps
    end
    add_index :lti_score_signatures, %i[lti_line_item_id lti_context_id],
              unique: true, name: 'index_lti_score_sigs_on_li_and_ctx'

    remove_column :lti_line_items, :last_pushed_signature, :string
  end
end
