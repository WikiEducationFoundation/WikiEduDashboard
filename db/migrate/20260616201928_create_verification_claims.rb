class CreateVerificationClaims < ActiveRecord::Migration[7.0]
  def change
    create_table :verification_claims do |t|
      t.text :sentence, null: false
      t.text :context
      t.text :cite_text
      t.text :source_url
      t.text :archive_url
      t.boolean :offline_source
      t.string :ref_id
      t.integer :article_id
      t.string :article_title
      t.integer :wiki_id, null: false
      t.integer :mw_rev_id
      t.integer :source_course_id
      t.integer :courses_users_id
      t.string :subject

      t.timestamps
    end

    add_index :verification_claims, :subject
    add_index :verification_claims, [:wiki_id, :mw_rev_id]
    add_index :verification_claims, :source_course_id
    add_index :verification_claims, :courses_users_id
  end
end
