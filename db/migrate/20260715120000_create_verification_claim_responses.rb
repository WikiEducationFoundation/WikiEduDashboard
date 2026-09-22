class CreateVerificationClaimResponses < ActiveRecord::Migration[7.0]
  def change
    create_table :verification_claim_responses do |t|
      t.integer :user_id, null: false
      t.integer :course_id, null: false
      t.integer :verification_claim_id, null: false
      t.string :source_access, null: false
      t.text :source_access_notes
      t.string :verdict
      t.text :claim_location
      t.text :verification_notes
      t.text :other_comments

      t.timestamps
    end

    # One response per claim a student takes on — deliberately NOT one per
    # student per course, so the exercise can grow to multiple claims.
    add_index :verification_claim_responses, [:user_id, :course_id, :verification_claim_id],
              unique: true, name: 'index_verification_claim_responses_uniqueness'
    add_index :verification_claim_responses, :course_id
    add_index :verification_claim_responses, :verification_claim_id
  end
end
