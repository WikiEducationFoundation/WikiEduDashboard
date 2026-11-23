# frozen_string_literal: true

# One person's evaluation of one Article Audit finding: whether it's accurate
# and whether it should be shown to program participants. A finding is
# identified by its check result and its index in that result's findings,
# which don't change once the result is saved; a re-run makes a new result.
class CreateArticleAuditFindingFeedbacks < ActiveRecord::Migration[8.1]
  def change
    create_table :article_audit_finding_feedbacks do |t|
      t.references :article_audit_check_result, null: false, index: false
      t.integer :finding_index, null: false
      t.references :user, null: false, index: true
      t.string :accurate
      t.text :accurate_comment
      t.string :show_to_participants
      t.text :show_to_participants_comment
      t.timestamps
    end
    add_index :article_audit_finding_feedbacks,
              %i[article_audit_check_result_id finding_index user_id],
              unique: true, name: 'index_article_audit_finding_feedbacks_on_finding_and_user'
  end
end
