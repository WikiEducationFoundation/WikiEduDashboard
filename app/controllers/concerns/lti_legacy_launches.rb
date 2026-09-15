# frozen_string_literal: true

# The refusals specific to LTI 1.1, mixed into LtiLaunchController: a legacy
# launch arriving at a deployment that has not opted into them, and the launch
# tokens we mint for the 1.1 launches we terminate ourselves.
#
# Separate from LtiLaunchSession, which establishes the session for launches of
# either version, so neither module carries the other's special cases.
module LtiLegacyLaunches
  extend ActiveSupport::Concern

  included do
    # A legacy launch reached a deployment with `lti_legacy_launches_enabled`
    # off. Fails closed like the platform gate: nothing downstream should run
    # for a launch kind the deployment hasn't opted into.
    rescue_from LtiSession::LegacyLaunchesDisabledError, with: :render_legacy_launches_disabled
    # Our own launch token. Expiry is the routine case — a Canvas tab left open
    # past 24 hours — and renders the same in-frame error a stale ltik does; a
    # token that does not verify is not routine and is reported.
    rescue_from LtiLegacyLaunchToken::Expired, LtiLegacyLaunchToken::Invalid,
                with: :render_launch_token_error
  end

  private

  # Reported rather than merely logged: once LTI 1.1 is available at all, an
  # institution can install the tool and start launching without anyone here
  # knowing, and this is how the operator finds out. Same bare 403 as the
  # platform gate, framing deliberately left blocked.
  def render_legacy_launches_disabled(error)
    Sentry.capture_exception(error)
    head :forbidden
  end

  def render_launch_token_error(error)
    if error.is_a?(LtiLegacyLaunchToken::Expired)
      Rails.logger.info("[LTI] expired legacy launch token on #{action_name}")
    else
      Sentry.capture_exception(error)
    end
    allow_iframe
    render 'lti_launch/launch_error', layout: 'lti_iframe', status: :unauthorized
  end
end
