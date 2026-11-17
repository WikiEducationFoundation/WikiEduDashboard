# frozen_string_literal: true

# The output of one check in an Article Audit. A check may be run more than
# once for the same audit (eg re-run with a different engine), so there is no
# uniqueness constraint on (article_audit_id, check_key).
class CreateArticleAuditCheckResults < ActiveRecord::Migration[8.1]
  def change
    create_table :article_audit_check_results do |t|
      t.references :article_audit, null: false, index: true
      t.string :check_key, null: false
      t.string :check_version
      t.string :engine
      t.string :status, null: false, default: 'running'
      t.text :error
      t.text :findings, size: :medium
      t.text :artifacts, size: :medium
      t.text :usage
      t.integer :duration_ms
      t.timestamps
    end
  end
end
