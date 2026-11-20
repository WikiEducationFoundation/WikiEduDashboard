# frozen_string_literal: true

# An Article Audit: a requested review of one revision of a wiki page, run as
# a set of independent checks. Each check's output is an
# article_audit_check_results row.
class CreateArticleAudits < ActiveRecord::Migration[8.1]
  def change
    create_table :article_audits do |t|
      t.integer :wiki_id, null: false
      t.integer :mw_rev_id, null: false
      t.integer :mw_page_id
      t.integer :namespace
      t.string :article_title
      t.string :url, limit: 1000
      t.integer :article_id
      t.integer :requester_id
      t.integer :course_id
      t.integer :user_id
      t.string :status, null: false, default: 'queued'
      t.text :error
      t.text :usage
      t.datetime :started_at
      t.datetime :completed_at
      t.timestamps
    end
    add_index :article_audits, %i[wiki_id mw_rev_id]
    add_index :article_audits, :requester_id
  end
end
