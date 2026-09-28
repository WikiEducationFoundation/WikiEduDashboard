# frozen_string_literal: true

require 'cgi'

# Where Canvas posts an LTI 1.1 launch. This is the endpoint LTIAAS used to
# provide for the legacy path; we terminate those launches ourselves so the
# consumer keys can be ours to issue, scope and revoke.
#
# A verified launch is redirected into the ordinary launch flow at
# `/lti?ltik=...`, carrying a token we signed rather than one LTIAAS minted.
# Nothing downstream can tell the difference.
class LtiLegacyLaunchesController < ApplicationController
  # Canvas's auto-submitting form arrives from the user's browser with no
  # Rails session behind it, so session-based CSRF neither applies nor could
  # succeed. The launch authenticates itself by its OAuth 1.0a signature.
  skip_before_action :verify_authenticity_token, only: :create

  before_action :require_legacy_launches_enabled

  def create
    verification = VerifyLtiLegacyLaunch.new(request)
    return refuse(verification) unless verification.valid?

    redirect_to "/lti?ltik=#{CGI.escape(launch_token(verification))}", status: :see_other
  end

  private

  def launch_token(verification)
    key = verification.consumer_key
    launch = verification.launch_params
    # Pins the key to this Canvas on its first launch; a bookkeeping stamp
    # afterwards.
    key.record_launch!(launch['tool_consumer_instance_guid'])
    idtoken = NormalizeLtiLegacyLaunch.new(launch, course_id: key.course_id).idtoken
    LtiLegacyLaunchToken.encode(idtoken)
  end

  # Every refusal renders the same page with the same status, whatever the
  # reason: telling an unknown consumer key apart from a bad signature would
  # let someone enumerate which keys exist. The reason goes to the log.
  def refuse(verification)
    report_refusal(verification)
    allow_iframe
    status = verification.error == :not_a_launch ? :bad_request : :unauthorized
    render 'lti_launch/launch_error', layout: 'lti_iframe', status:
  end

  # A mistyped shared secret is the commonest cause of a bad signature during
  # setup, and an instructor's typo is not an incident — the install guide
  # troubleshoots it. The same goes for a stale timestamp and a key that has
  # been regenerated or expired. What does get reported is a launch that
  # cannot be explained that way: a consumer key we never issued, a replayed
  # signature, a key used from a Canvas it is not pinned to, or a correctly
  # signed launch that names no Canvas instance at all.
  ROUTINE_REFUSALS = %i[not_a_launch bad_signature stale_timestamp unusable_key].freeze

  # An unknown key is the one refusal reachable with no knowledge of any key,
  # so an unauthenticated POST loop from one address could otherwise raise a
  # Sentry event per request. It stays reported — a key we never issued is
  # worth hearing about — but once per address per interval. Every refusal
  # still goes to the log.
  UNKNOWN_KEY_REPORT_INTERVAL = 1.hour

  def report_refusal(verification)
    detail = "reason=#{verification.error} key_id=#{verification.consumer_key&.id.inspect}"
    if report?(verification.error)
      Sentry.capture_message("LTI 1.1 launch refused: #{detail}")
    else
      Rails.logger.info("[LTI 1.1] refused launch: #{detail}")
    end
  end

  def report?(reason)
    return false if ROUTINE_REFUSALS.include?(reason)
    return true unless reason == :unknown_key

    unknown_key_report_due?
  end

  # The first increment in a window creates the counter with the window's
  # expiry, so only it returns 1. A cache that is down returns nil, and then
  # every refusal is reported, as before the throttle: visibility over quiet.
  def unknown_key_report_due?
    count = Rails.cache.increment("lti_legacy_unknown_key_reports/#{request.remote_ip}", 1,
                                  expires_in: UNKNOWN_KEY_REPORT_INTERVAL)
    count.nil? || count == 1
  end

  def require_legacy_launches_enabled
    return if Features.canvas_integration? && Features.lti_legacy_launches?

    head :not_found
  end

  # The refusal renders inside the Canvas iframe, so it has to be framable —
  # a bare error page that the browser refuses to frame tells the instructor
  # nothing at all.
  def allow_iframe
    response.headers.except! 'X-Frame-Options'
  end
end
