# frozen_string_literal: true

require 'jwt'

# Our replacement for LTIAAS's `ltik`: the token a verified LTI 1.1 launch is
# redirected with, and which every follow-up request inside the partitioned
# Canvas iframe re-presents.
#
# A signed JWT carrying the normalized idtoken, so no table and no cleanup job
# are needed and the token is re-presentable for its lifetime exactly as the
# LTIAAS one is. What that gives up is revocation inside the window, which is
# acceptable when the token's whole authority is showing one course's own data
# in an iframe.
#
# The prefix is what lets LtiSession tell our token from an LTIAAS one without
# trying to decode it first.
class LtiLegacyLaunchToken
  PREFIX = 'lti11.'
  LIFETIME = 24.hours
  ALGORITHM = 'HS256'

  # A token that is past its 24 hours. Routine: a Canvas tab left open
  # overnight produces one, and the remedy is to reload the Canvas page.
  class Expired < StandardError; end

  # A token that does not verify: truncated, tampered with, or signed with a
  # different secret. Not routine.
  class Invalid < StandardError; end

  def self.ours?(token)
    token.to_s.start_with?(PREFIX)
  end

  def self.encode(idtoken)
    payload = { 'idt' => idtoken, 'iat' => Time.now.to_i,
                'exp' => LIFETIME.from_now.to_i, 'jti' => SecureRandom.uuid }
    PREFIX + JWT.encode(payload, secret, ALGORITHM)
  end

  def self.decode(token)
    payload, = JWT.decode(token.to_s.delete_prefix(PREFIX), secret, true, algorithm: ALGORITHM)
    payload.fetch('idt')
  rescue JWT::ExpiredSignature
    raise Expired
  rescue JWT::DecodeError, KeyError
    raise Invalid
  end

  # Outside production, fall back to a fixed non-secret value so the suite and
  # a developer whose application.yml predates this feature both work. In
  # production a missing secret is fatal for this path rather than silently
  # signing tokens anyone could forge.
  def self.secret
    configured = ENV.fetch('lti_legacy_launch_token_secret', nil)
    return configured if configured.present?
    raise Invalid, 'lti_legacy_launch_token_secret is not configured' if Rails.env.production?

    'development_only_launch_token_secret_not_a_secret'
  end
end
