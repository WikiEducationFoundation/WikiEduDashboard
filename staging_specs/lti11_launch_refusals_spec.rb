# frozen_string_literal: true

require_relative 'spec_helper'
require 'net/http'
require 'uri'
require 'securerandom'
require 'oauth'
require 'oauth/signature/hmac/sha1'
require 'oauth/request_proxy/mock_request'

# The refusal half of the self-hosted LTI 1.1 endpoint, exercised against the
# deployed staging app over plain HTTP. No browser: a launch is an OAuth 1.0a
# signed form POST, so this spec signs its own and reads the status line.
#
# `lti11_legacy_launch_spec.rb` proves a real Canvas launch works. This one
# proves the things that must *not* work, which a real Canvas cannot be made to
# do on demand: a replayed signature, a mistyped secret, a stale clock, a key
# we never issued, a signature computed over somebody else's URL, and a launch
# that names no Canvas instance at all.
#
# It also checks the property the endpoint's comments promise: an unknown
# consumer key and a bad signature are indistinguishable in the response, so
# the endpoint cannot be used to enumerate which keys exist.
describe 'LTI 1.1 launch refusals', :staging do
  let(:required_env) do
    %w[WIKIPEDIA_TEST_INSTRUCTOR_USERNAME DASHBOARD_TEST_CAMPAIGN_SLUG]
  end
  let(:run_id) { Time.now.strftime('%Y%m%d%H%M%S') }
  let(:dashboard_base) { ENV.fetch('DASHBOARD_BASE_URL', 'https://dashboard-testing.wikiedu.org') }
  let(:launch_url) { "#{dashboard_base}/lti/legacy/launch" }
  let(:context_title) { "Refusal Matrix #{run_id}" }
  let(:canvas_guid) { 'Uo7bOjy7KUKkxZthLY1dxpzh4sKpmAvsBnvmSgGQ:canvas-lms' }
  let(:provisioned) { @provisioned ||= {} }

  before do
    missing = required_env.select { |k| ENV[k].to_s.empty? }
    skip("missing env vars: #{missing.join(', ')}") if missing.any?

    course = DashboardAdminClient.create_course(
      title: "Refusal Matrix #{run_id}", school: 'StagingTest', term: run_id,
      instructor_username: ENV.fetch('WIKIPEDIA_TEST_INSTRUCTOR_USERNAME')
    )
    provisioned[:slug] = course['slug']
    DashboardAdminClient.approve_course(slug: course['slug'],
                                        campaign_slug: ENV.fetch('DASHBOARD_TEST_CAMPAIGN_SLUG'))
    @credentials = DashboardAdminClient.issue_lti_consumer_key(
      course_slug: course['slug'],
      instructor_username: ENV.fetch('WIKIPEDIA_TEST_INSTRUCTOR_USERNAME')
    )
  end

  after do
    next unless provisioned[:slug]

    DashboardAdminClient.delete_bindings_for(context_title:)
    DashboardAdminClient.delete_course(slug: provisioned[:slug])
  end

  # The parameters a real Canvas 1.1 launch carries, minus the signature.
  # Timestamp and nonce are per-call so each launch is fresh by default.
  def launch_params(timestamp: Time.now.to_i, key: @credentials['key'])
    { 'oauth_consumer_key' => key, 'oauth_signature_method' => 'HMAC-SHA1',
      'oauth_timestamp' => timestamp.to_s, 'oauth_nonce' => SecureRandom.hex(16),
      'oauth_version' => '1.0', 'oauth_callback' => 'about:blank',
      'lti_message_type' => 'basic-lti-launch-request', 'lti_version' => 'LTI-1p0',
      'context_id' => SecureRandom.hex(20), 'context_label' => 'ENVS-350',
      'context_title' => context_title,
      'launch_presentation_document_target' => 'iframe',
      'launch_presentation_return_url' =>
        'https://canvas.wikiedu.org/courses/1/external_content/success/external_tool_redirect',
      'resource_link_id' => SecureRandom.hex(20), 'resource_link_title' => 'wikiedu.org',
      'roles' => 'Instructor', 'tool_consumer_info_product_family_code' => 'canvas',
      'tool_consumer_info_version' => 'cloud',
      'tool_consumer_instance_guid' => canvas_guid,
      'tool_consumer_instance_name' => 'WikiEduDashboard',
      'user_id' => SecureRandom.hex(20) }
  end

  # What Canvas does before it posts the form.
  def sign(params, secret: @credentials['secret'], url: launch_url)
    signature = OAuth::Signature.sign(
      { 'method' => 'POST', 'uri' => url, 'parameters' => params },
      consumer_secret: secret
    )
    params.merge('oauth_signature' => signature)
  end

  def post_launch(signed)
    uri = URI.parse(launch_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    request = Net::HTTP::Post.new(uri.path)
    request.set_form_data(signed)
    http.request(request)
  end

  # Status plus body, because the point of several of these cases is that two
  # different reasons produce the same response. The CSRF token Rails embeds in
  # every rendered page is masked per response and so differs between any two
  # requests; it says nothing about why a launch was refused, so it is blanked
  # before two refusals are compared.
  def refusal(signed)
    response = post_launch(signed)
    body = response.body.to_s.gsub(/(name="csrf-token" content=)"[^"]*"/, '\1"[csrf]"')
    { code: response.code, body: }
  end

  it 'accepts a well-formed launch and refuses every malformed one identically' do
    # First, a signed launch that names no Canvas instance, posted while the
    # key is still unpinned. Accepting it would activate the key without a pin
    # and leave it usable from anywhere, so it is refused and the key is left
    # untouched; the well-formed launch below is then the one that pins it.
    unidentified = refusal(sign(launch_params.except('tool_consumer_instance_guid')))
    warn "  [refusals] launch with no instance guid: #{unidentified[:code]}"
    expect(unidentified[:code]).to eq('401')
    untouched = DashboardAdminClient.consumer_key_state(course_slug: provisioned[:slug])
    expect(untouched.values_at('activated_at', 'lms_instance_guid')).to all(be_nil)

    # A launch the endpoint should accept, first, so the rest are refusals of
    # something that would otherwise have worked. This one also pins the key to
    # this Canvas, which the wrong-Canvas case below then trips over.
    signed = sign(launch_params)
    accepted = post_launch(signed)
    warn "  [refusals] valid launch: #{accepted.code} -> #{accepted['Location']}"
    expect(accepted.code).to eq('303')
    # Rails expands the controller's relative redirect into an absolute URL,
    # so this asserts the host as well as the path and the token's prefix.
    expect(accepted['Location']).to start_with("#{dashboard_base}/lti?ltik=lti11.")

    aggregate_failures 'refusals' do
      # Replay: the same bytes Canvas signed, posted a second time. The nonce
      # store is what catches this; the signature is still perfectly valid.
      replayed = refusal(signed)
      warn "  [refusals] replayed signature: #{replayed[:code]}"
      expect(replayed[:code]).to eq('401')

      # A mistyped shared secret, the commonest setup mistake.
      bad_secret = refusal(sign(launch_params, secret: 'not-the-shared-secret'))
      warn "  [refusals] wrong secret: #{bad_secret[:code]}"
      expect(bad_secret[:code]).to eq('401')

      # A key we never issued. This must be indistinguishable from the bad
      # secret above, or the endpoint answers "does this key exist?".
      unknown_key = refusal(sign(launch_params(key: SecureRandom.hex(20))))
      warn "  [refusals] unknown key: #{unknown_key[:code]}"
      expect(unknown_key[:code]).to eq('401')
      expect(unknown_key[:body]).to eq(bad_secret[:body])

      # A correctly signed launch whose clock is outside the window. Captured
      # form bodies stop being useful once they age out.
      stale = refusal(sign(launch_params(timestamp: Time.now.to_i - 20 * 60)))
      warn "  [refusals] stale timestamp: #{stale[:code]}"
      expect(stale[:code]).to eq('401')

      # A signature computed over a different URL. This is the check that the
      # base string comes from our own configuration rather than from anything
      # the request carries: if the endpoint signed against the Host it was
      # given, this would verify.
      elsewhere = refusal(sign(launch_params, url: 'https://evil.example/lti/legacy/launch'))
      warn "  [refusals] signed for another URL: #{elsewhere[:code]}"
      expect(elsewhere[:code]).to eq('401')

      # Not a launch at all: a correctly signed POST carrying some other LTI
      # message type. Refused before the key is even looked up.
      other_message = launch_params.merge('lti_message_type' => 'ContentItemSelectionRequest')
      not_a_launch = refusal(sign(other_message))
      warn "  [refusals] wrong message type: #{not_a_launch[:code]}"
      expect(not_a_launch[:code]).to eq('400')

      # A perfectly valid launch from the wrong Canvas. The first accepted
      # launch pinned this key to one instance guid; a key that leaks out of
      # one institution cannot be used to launch from another. This is
      # authorization rather than authenticity, so it is checked last.
      other_canvas = launch_params.merge('tool_consumer_instance_guid' => 'some-other:canvas-lms')
      wrong_canvas = refusal(sign(other_canvas))
      warn "  [refusals] launch from another Canvas: #{wrong_canvas[:code]}"
      expect(wrong_canvas[:code]).to eq('401')
    end
  end
end
