# frozen_string_literal: true
# == Schema Information
#
# Table name: lti_legacy_launches
#
#  id         :bigint           not null, primary key
#  token      :string(255)      not null - the bearer token we redirect with
#  idtoken    :text(65535)      not null - the normalized launch, as JSON
#  expires_at :datetime         not null
#  created_at :datetime         not null
#

# One verified LTI 1.1 launch, held for as long as its token is good for.
#
# This is what LtiLegacyLaunchToken hands out a reference to. The launch's
# claims live here rather than inside the token because the token has to fit
# in a session cookie during the Wikipedia OAuth break-out; see the migration.
# Keeping them server-side also makes a launch revocable, which a self-contained
# token could not be.
class LtiLegacyLaunch < ApplicationRecord
  def self.sweep
    where(expires_at: ...Time.current).delete_all
  end

  def expired?
    expires_at <= Time.current
  end

  def claims
    JSON.parse(idtoken)
  end
end
