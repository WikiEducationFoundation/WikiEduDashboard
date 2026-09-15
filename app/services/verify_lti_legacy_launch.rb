# frozen_string_literal: true

require 'oauth'
require 'oauth/signature/hmac/sha1'
require 'oauth/request_proxy/action_dispatch_request'

# Verifies an inbound LTI 1.1 launch: the OAuth 1.0a signature Canvas computed
# with one of our issued consumer keys, plus the freshness and replay checks
# that make a captured signature useless to anyone who observes it.
#
# This is the half of the launch LTIAAS used to do for us. Everything it
# accepts is handed on as an idtoken-shaped hash by NormalizeLtiLegacyLaunch,
# so nothing downstream of LtiSession can tell the difference.
#
# `#error` names the reason a launch was refused, for logging. Callers must not
# vary what they *render* by reason: telling an unknown consumer key apart from
# a bad signature would let someone enumerate which keys exist.
class VerifyLtiLegacyLaunch
  MESSAGE_TYPE = 'basic-lti-launch-request'
  LTI_VERSION = 'LTI-1p0'

  # How far a launch's own clock may be from ours. Canvas signs a timestamp;
  # without a window, a signature captured from a browser's history could be
  # replayed forever. Five minutes is the usual allowance for clock skew.
  TIMESTAMP_WINDOW = 5.minutes

  attr_reader :consumer_key, :error

  def initialize(request)
    @request = request
    @params = request.request_parameters
    perform
  end

  def valid?
    @error.nil?
  end

  def launch_params
    @params
  end

  # The URL Canvas signed, reconstructed from configuration rather than read
  # off the request. The signature covers it, so trusting the request's own
  # Host would let a proxy or a spoofed header change the base string —
  # and this is the single place it is defined, shared with the config XML
  # Canvas was installed from, so the two cannot drift.
  def self.launch_url
    "https://#{ENV.fetch('dashboard_url')}/lti/legacy/launch"
  end

  private

  def perform
    return @error = :not_a_launch unless launch_message?

    @consumer_key = LtiConsumerKey.find_by(key: @params['oauth_consumer_key'])
    return @error = :unknown_key if @consumer_key.nil?
    return @error = :unusable_key unless @consumer_key.active? && !@consumer_key.expired?
    return @error = :bad_signature unless signature_valid?
    return @error = :stale_timestamp unless timestamp_fresh?
    return @error = :replay unless nonce_unseen?

    # Last, because it is authorization rather than authenticity: the guid is
    # only meaningful once the signature proves the launch is really from the
    # holder of this key.
    @error = :wrong_canvas unless @consumer_key.usable_for?(instance_guid)
  end

  def launch_message?
    @params['lti_message_type'] == MESSAGE_TYPE && @params['lti_version'] == LTI_VERSION
  end

  def signature_valid?
    OAuth::Signature.verify(@request, uri: self.class.launch_url,
                                      consumer_secret: @consumer_key.secret)
  rescue StandardError
    # A malformed or absent signature raises out of the gem rather than
    # returning false; either way the launch is refused.
    false
  end

  def timestamp_fresh?
    timestamp = @params['oauth_timestamp'].to_i
    return false if timestamp.zero?

    (Time.now.to_i - timestamp).abs <= TIMESTAMP_WINDOW.to_i
  end

  # The unique index does the work: a check-then-insert would let two
  # simultaneous replays both pass. Sweeping here keeps the table to the
  # handful of rows a live window can hold.
  def nonce_unseen?
    LtiLaunchNonce.sweep
    LtiLaunchNonce.create!(lti_consumer_key: @consumer_key, nonce: @params['oauth_nonce'])
    true
  rescue ActiveRecord::RecordNotUnique
    false
  end

  def instance_guid
    @params['tool_consumer_instance_guid']
  end
end
