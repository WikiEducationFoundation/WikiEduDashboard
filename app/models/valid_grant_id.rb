# frozen_string_literal: true
# == Schema Information
#
# Table name: valid_grant_ids
#
#  id         :bigint           not null, primary key
#  grant_id   :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

#= A grant ID that courses may be linked to.
#= The list is copied from the grant ID spreadsheet by GrantIdList.
class ValidGrantId < ApplicationRecord
  # Swaps the stored list for a new one in a single transaction, so
  # validation never sees a half-written list.
  def self.replace_all(grant_ids)
    now = Time.zone.now
    rows = grant_ids.uniq.map { |grant_id| { grant_id:, created_at: now, updated_at: now } }
    transaction do
      delete_all
      insert_all(rows) if rows.any?
    end
  end
end
