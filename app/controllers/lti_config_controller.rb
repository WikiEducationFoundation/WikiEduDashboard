# frozen_string_literal: true

# Serves the LTI 1.1 tool configuration — an IMS "cartridge" XML — that a
# Canvas admin installs "By URL" (or pastes) when adding the Dashboard's legacy
# tool. It exists because a hand-entered 1.1 tool (key, secret, launch URL) has
# no course-navigation placement at all; Canvas only takes placements from an
# XML configuration or the API, and LTIAAS provides no XML for legacy tools.
#
# The XML points at our own legacy launch endpoint, asks Canvas for the
# anonymous privacy level (no names or emails, as the 1.3 registration does),
# and declares one placement: course navigation, on by default, the same
# posture as the 1.3 tool. The consumer key and shared secret are NOT in here —
# Canvas asks for them alongside the URL, and an instructor gets them from the
# credentials page under their own course.
#
# Public and unauthenticated: Canvas fetches it server-side. Gated on the same
# flags as the launches it configures, so a deployment that would refuse a
# legacy launch doesn't advertise one.
class LtiConfigController < ApplicationController
  def legacy
    return head :not_found unless Features.canvas_integration? && Features.lti_legacy_launches?

    # The same definition the verifier reconstructs the signature's base
    # string from, so the URL Canvas signs and the URL we check against cannot
    # drift apart.
    @launch_url = VerifyLtiLegacyLaunch.launch_url
    render :legacy, formats: :xml, layout: false
  end
end
