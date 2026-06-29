# frozen_string_literal: true

class AddMwRevTimestampToVerificationClaims < ActiveRecord::Migration[8.1]
  def change
    add_column :verification_claims, :mw_rev_timestamp, :datetime
  end
end
