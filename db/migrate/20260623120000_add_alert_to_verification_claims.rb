# frozen_string_literal: true

class AddAlertToVerificationClaims < ActiveRecord::Migration[8.1]
  def change
    add_column :verification_claims, :alert_id, :integer
    add_index :verification_claims, :alert_id
  end
end
