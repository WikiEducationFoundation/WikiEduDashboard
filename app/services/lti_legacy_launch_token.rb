# frozen_string_literal: true

# Our replacement for LTIAAS's `ltik`: the token a verified LTI 1.1 launch is
# redirected with, and which every follow-up request inside the partitioned
# Canvas iframe re-presents.
#
# An unguessable reference to an LtiLegacyLaunch row, not a self-contained
# token. It began as a JWT carrying the normalized idtoken, which passed every
# test and then failed against real Canvas: `LtiLaunchController#connect_course`
# stashes the token in the Rails session so the Wikipedia OAuth callback can
# return to the launch, and a token that size overflowed the 4 KB session
# cookie. LTIAAS's ltik is short for exactly this reason.
#
# Being server-side state, it is also revocable, which a signed token would not
# have been.
#
# The prefix lets LtiSession tell our token from an LTIAAS one without a lookup.
class LtiLegacyLaunchToken
  PREFIX = 'lti11.'
  LIFETIME = 24.hours

  # A token whose launch is past its 24 hours, or has been swept. Routine: a
  # Canvas tab left open overnight produces one, and the remedy is to reload
  # the Canvas page.
  class Expired < StandardError; end

  # A token that names no launch at all: truncated, mistyped, or invented.
  class Invalid < StandardError; end

  def self.ours?(token)
    token.to_s.start_with?(PREFIX)
  end

  def self.encode(idtoken)
    LtiLegacyLaunch.sweep
    token = SecureRandom.urlsafe_base64(32)
    LtiLegacyLaunch.create!(token:, idtoken: idtoken.to_json,
                            expires_at: LIFETIME.from_now)
    "#{PREFIX}#{token}"
  end

  def self.decode(token)
    launch = LtiLegacyLaunch.find_by(token: token.to_s.delete_prefix(PREFIX))
    raise Invalid, 'no such launch' if launch.nil?
    raise Expired, 'launch token has expired' if launch.expired?

    launch.claims
  end
end
