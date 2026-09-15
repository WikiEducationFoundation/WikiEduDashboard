# frozen_string_literal: true

require 'rails_helper'
require 'oauth'
require 'oauth/signature/hmac/sha1'
require 'oauth/request_proxy/mock_request'

describe VerifyLtiLegacyLaunch do
  let(:course) { create(:course) }
  let(:instructor) { create(:user) }
  let!(:consumer_key) { LtiConsumerKey.generate_for(course:, user: instructor) }
  let(:guid) { 'Uo7bOjy7KUKkxZthLY1dxpzh4sKpmAvsBnvmSgGQ:canvas-lms' }

  before { ENV['dashboard_url'] = 'dashboard.wikiedu.org' }

  # The parameter set a real Canvas 1.1 launch carried, captured from
  # canvas.wikiedu.org on 2026-09-15, minus the signature Canvas computes.
  def launch_params(overrides = {})
    { 'oauth_consumer_key' => consumer_key.key, 'oauth_signature_method' => 'HMAC-SHA1',
      'oauth_timestamp' => Time.now.to_i.to_s, 'oauth_nonce' => SecureRandom.hex(16),
      'oauth_version' => '1.0', 'oauth_callback' => 'about:blank',
      'lti_message_type' => 'basic-lti-launch-request', 'lti_version' => 'LTI-1p0',
      'context_id' => '2300c772b3df735be28419065e87fd6a1a24e102',
      'context_label' => 'ENVS-350', 'context_title' => 'Environmental Policy',
      'custom_canvas_enrollment_state' => 'active',
      'launch_presentation_document_target' => 'iframe',
      'launch_presentation_return_url' => 'https://canvas.example.edu/courses/1/external_content',
      'resource_link_id' => '2300c772b3df735be28419065e87fd6a1a24e102',
      'resource_link_title' => 'wikiedu.org', 'roles' => 'Instructor',
      'tool_consumer_info_product_family_code' => 'canvas',
      'tool_consumer_info_version' => 'cloud',
      'tool_consumer_instance_guid' => guid,
      'tool_consumer_instance_name' => 'Example University',
      'user_id' => '86157096483e6b3a50bfedc6bac902c0b20a824f' }.merge(overrides)
  end

  # Sign the way Canvas does: over the tool URL it was configured with.
  def sign(params, secret: consumer_key.secret, url: described_class.launch_url)
    signature = OAuth::Signature.sign(
      { 'method' => 'POST', 'uri' => url, 'parameters' => params }, consumer_secret: secret
    )
    params.merge('oauth_signature' => signature)
  end

  # The request as it reaches us behind the proxy, whose Host is deliberately
  # not the host Canvas signed.
  def verify(signed, host: 'proxy-internal.invalid')
    env = Rack::MockRequest.env_for("http://#{host}/lti/legacy/launch",
                                    method: 'POST', params: signed)
    described_class.new(ActionDispatch::Request.new(env))
  end

  it 'accepts a launch signed with the course\'s key' do
    result = verify(sign(launch_params))
    expect(result).to be_valid
    expect(result.error).to be_nil
    expect(result.consumer_key).to eq(consumer_key)
  end

  # The classic failure for a self-hosted launch endpoint: the signature covers
  # the URL Canvas posted to, so it has to be reconstructed from configuration
  # rather than read off a request that has been through a proxy.
  it 'verifies against the configured URL, not the request\'s own host' do
    expect(verify(sign(launch_params), host: 'anything-at-all.invalid')).to be_valid
  end

  it 'refuses a signature computed for a different tool URL' do
    signed = sign(launch_params, url: 'https://evil.example/lti/legacy/launch')
    expect(verify(signed).error).to eq(:bad_signature)
  end

  it 'refuses a wrong shared secret' do
    expect(verify(sign(launch_params, secret: 'not-the-secret')).error).to eq(:bad_signature)
  end

  it 'refuses a launch whose parameters were altered after signing' do
    signed = sign(launch_params).merge('user_id' => 'somebody-else')
    expect(verify(signed).error).to eq(:bad_signature)
  end

  it 'refuses a consumer key we never issued' do
    signed = sign(launch_params('oauth_consumer_key' => 'made-up-key'))
    expect(verify(signed).error).to eq(:unknown_key)
  end

  it 'refuses a deactivated key' do
    consumer_key.update!(active: false)
    expect(verify(sign(launch_params)).error).to eq(:unusable_key)
  end

  it 'refuses a key that was issued and never used' do
    travel_to((LtiConsumerKey::UNACTIVATED_LIFETIME + 1.day).from_now) do
      expect(verify(sign(launch_params)).error).to eq(:unusable_key)
    end
  end

  it 'refuses anything that is not a basic launch' do
    signed = sign(launch_params('lti_message_type' => 'ToolProxyRegistrationRequest'))
    expect(verify(signed).error).to eq(:not_a_launch)
  end

  describe 'freshness' do
    it 'refuses a launch signed too long ago' do
      signed = sign(launch_params('oauth_timestamp' => 10.minutes.ago.to_i.to_s))
      expect(verify(signed).error).to eq(:stale_timestamp)
    end

    it 'refuses a launch from too far in the future' do
      signed = sign(launch_params('oauth_timestamp' => 10.minutes.from_now.to_i.to_s))
      expect(verify(signed).error).to eq(:stale_timestamp)
    end

    it 'allows modest clock skew' do
      signed = sign(launch_params('oauth_timestamp' => 2.minutes.ago.to_i.to_s))
      expect(verify(signed)).to be_valid
    end
  end

  describe 'replay' do
    it 'refuses the same signed launch a second time' do
      signed = sign(launch_params)
      expect(verify(signed)).to be_valid
      expect(verify(signed).error).to eq(:replay)
    end

    it 'allows a fresh launch from the same key' do
      expect(verify(sign(launch_params))).to be_valid
      expect(verify(sign(launch_params))).to be_valid
    end

    # The index is the enforcement, so a nonce is remembered for longer than a
    # launch bearing it could still pass the timestamp check.
    it 'keeps nonces for longer than the timestamp window' do
      verify(sign(launch_params))
      expect(LtiLaunchNonce.count).to eq(1)
      travel_to(2.minutes.from_now) { verify(sign(launch_params)) }
      expect(LtiLaunchNonce.count).to eq(2)
    end

    it 'sweeps nonces too old to matter' do
      verify(sign(launch_params))
      travel_to((LtiLaunchNonce::LIFETIME + 1.minute).from_now) { verify(sign(launch_params)) }
      expect(LtiLaunchNonce.count).to eq(1)
    end
  end

  describe 'the Canvas instance pin' do
    it 'accepts the first launch from any Canvas, which is what pins the key' do
      expect(verify(sign(launch_params))).to be_valid
    end

    it 'refuses a launch from a different Canvas once the key is pinned' do
      consumer_key.record_launch!('the-real-canvas')
      expect(verify(sign(launch_params)).error).to eq(:wrong_canvas)
    end

    it 'accepts later launches from the Canvas it is pinned to' do
      consumer_key.record_launch!(guid)
      expect(verify(sign(launch_params))).to be_valid
    end
  end
end
