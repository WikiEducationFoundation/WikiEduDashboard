class CreateVerificationClaimAssignments < ActiveRecord::Migration[7.0]
  def change
    create_table :verification_claim_assignments do |t|
      t.integer :user_id, null: false
      t.integer :course_id, null: false
      t.integer :verification_claim_id, null: false

      t.timestamps
    end

    add_index :verification_claim_assignments, [:user_id, :course_id], unique: true
    add_index :verification_claim_assignments, :verification_claim_id
  end
end
