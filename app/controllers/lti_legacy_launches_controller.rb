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
  # signature, or a key used from a Canvas it is not pinned to.
  ROUTINE_REFUSALS = %i[not_a_launch bad_signature stale_timestamp unusable_key].freeze

  def report_refusal(verification)
    detail = "reason=#{verification.error} key_id=#{verification.consumer_key&.id.inspect}"
    if ROUTINE_REFUSALS.include?(verification.error)
      Rails.logger.info("[LTI 1.1] refused launch: #{detail}")
    else
      Sentry.capture_message("LTI 1.1 launch refused: #{detail}")
    end
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
