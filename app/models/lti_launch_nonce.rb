# frozen_string_literal: true
# == Schema Information
#
# Table name: lti_launch_nonces
#
#  id                  :bigint           not null, primary key
#  lti_consumer_key_id :integer          not null
#  nonce               :string(255)      not null
#  created_at          :datetime         not null
#

# One seen OAuth 1.0a nonce, so a signed LTI 1.1 launch cannot be replayed.
# Rows older than the timestamp window are useless — a launch that old is
# refused on its timestamp anyway — so they are swept as launches pass through
# rather than by a scheduled job.
class LtiLaunchNonce < ApplicationRecord
  # Comfortably longer than VerifyLtiLegacyLaunch::TIMESTAMP_WINDOW, so a nonce
  # is never forgotten while a launch bearing it could still be accepted.
  LIFETIME = 10.minutes

  belongs_to :lti_consumer_key

  def self.sweep
    where(created_at: ...LIFETIME.ago).delete_all
  end
end
