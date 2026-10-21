# frozen_string_literal: true

require 'rails_helper'
require 'oauth'
require 'oauth/signature/hmac/sha1'
require 'oauth/request_proxy/mock_request'

describe LtiLegacyLaunchesController, type: :request do
  let(:instructor) { create(:user, username: 'Prof') }
  let(:course) { create(:course, slug: 'School/Environmental_Policy_(2026)') }
  let!(:consumer_key) { LtiConsumerKey.generate_for(course:, user: instructor) }
  let(:guid) { 'Uo7bOjy7:canvas-lms' }
  let(:signed_in_user) { nil }

  before do
    ENV['dashboard_url'] = 'dashboard.wikiedu.org'
    allow(Features).to receive_messages(canvas_integration?: true, lti_legacy_launches?: true)
    CoursesUsers.create!(user: instructor, course:, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    course.campaigns << Campaign.first
    allow_any_instance_of(ApplicationController)
      .to receive(:current_user).and_return(signed_in_user)
  end

  def launch_params(overrides = {})
    { 'oauth_consumer_key' => consumer_key.key, 'oauth_signature_method' => 'HMAC-SHA1',
      'oauth_timestamp' => Time.now.to_i.to_s, 'oauth_nonce' => SecureRandom.hex(16),
      'oauth_version' => '1.0', 'oauth_callback' => 'about:blank',
      'lti_message_type' => 'basic-lti-launch-request', 'lti_version' => 'LTI-1p0',
      'context_id' => 'canvas-course-77', 'context_title' => 'ENVS 350',
      'resource_link_id' => 'canvas-course-77', 'resource_link_title' => 'wikiedu.org',
      'launch_presentation_return_url' => 'https://canvas.example.edu/courses/1/external_content',
      'roles' => 'Instructor', 'tool_consumer_instance_guid' => guid,
      'tool_consumer_info_product_family_code' => 'canvas',
      'user_id' => 'canvas-user-1' }.merge(overrides)
  end

  def sign(params, secret: consumer_key.secret)
    signature = OAuth::Signature.sign(
      { 'method' => 'POST', 'uri' => VerifyLtiLegacyLaunch.launch_url, 'parameters' => params },
      consumer_secret: secret
    )
    params.merge('oauth_signature' => signature)
  end

  def launch(params = sign(launch_params))
    post '/lti/legacy/launch', params:
  end

  describe 'a launch Canvas signed with a key we issued' do
    it 'redirects into the ordinary launch flow with a token of ours' do
      launch
      expect(response).to have_http_status(:see_other)
      expect(response.location).to include('/lti?ltik=')
      expect(CGI.unescape(response.location)).to include(LtiLegacyLaunchToken::PREFIX)
    end

    it 'pins the key to this Canvas and records the launch' do
      expect { launch }.to change { consumer_key.reload.activated_at }.from(nil)
      expect(consumer_key.reload.lms_instance_guid).to eq(guid)
      expect(consumer_key.last_launch_at).to be_present
    end

    # The whole point of issuing the key from a course page: the instructor
    # never sees the setup picker, because the key already knew the course.
    context 'when the instructor follows the redirect' do
      let(:signed_in_user) { instructor }

      it 'binds the course automatically' do
        launch
        follow_redirect!
        binding = LtiCourseBinding.find_by(lms_id: guid, lms_context_id: 'canvas-course-77')
        expect(binding.course).to eq(course)
        expect(binding.lti_version).to eq('1.2.0')
        expect(binding.ltiaas_service_credentials).to be_nil
      end

      it 'asks them to connect their Wikipedia account rather than linking it for them' do
        launch
        follow_redirect!
        expect(response).to render_template('lti_launch/connect_identity')
        expect(LtiContext.count).to eq(0)
      end

      # Once connected, the launch-only status view renders: no picker, because
      # the course is already bound.
      it 'goes straight to the status view once the account is connected' do
        launch
        ltik = CGI.parse(URI.parse(response.location).query)['ltik'].first
        follow_redirect!
        post '/lti/connect_identity', params: { ltik: }
        expect(response).to render_template('lti_launch/instructor_status_legacy')
        expect(response).not_to render_template('lti_launch/setup')
      end
    end

    # Inside the Canvas iframe there is no Dashboard session, which is the
    # normal state; the launch still authenticates and the landing offers the
    # break-out to a new tab.
    it 'shows the sign-in landing when nobody is signed in' do
      launch
      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Open the Wiki Education Dashboard')
    end
  end

  describe 'refusals' do
    before { allow(Sentry).to receive(:capture_message) }

    it 'refuses a bad signature in-frame, so the iframe can show it' do
      launch(sign(launch_params, secret: 'not-the-secret'))
      expect(response).to have_http_status(:unauthorized)
      expect(response).to render_template('lti_launch/launch_error')
      expect(response.headers).not_to have_key('X-Frame-Options')
    end

    # Distinguishing an unknown key from a bad signature would let someone
    # enumerate which keys exist, so the two must be indistinguishable.
    it 'answers an unknown key exactly as it answers a bad signature' do
      launch(sign(launch_params, secret: 'not-the-secret'))
      bad_signature = [response.status, response.body]
      launch(sign(launch_params('oauth_consumer_key' => 'never-issued')))
      expect([response.status, response.body]).to eq(bad_signature)
    end

    it 'refuses a replayed launch' do
      signed = sign(launch_params)
      launch(signed)
      launch(signed)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'treats a non-launch POST as malformed rather than unauthorized' do
      launch(sign(launch_params('lti_message_type' => 'something-else')))
      expect(response).to have_http_status(:bad_request)
    end

    it 'creates no binding for a refused launch' do
      expect { launch(sign(launch_params, secret: 'not-the-secret')) }
        .not_to change(LtiCourseBinding, :count)
    end

    # A correctly signed launch with no instance guid must not consume the
    # first-launch pin: accepted, it would activate the key unpinned, and the
    # key would then work from any Canvas for good.
    it 'refuses a launch that names no Canvas instance and leaves the key unactivated' do
      launch(sign(launch_params.except('tool_consumer_instance_guid')))
      expect(response).to have_http_status(:unauthorized)
      expect(consumer_key.reload).not_to be_activated
    end

    # The key is deleted with its course, so the launch is refused as an
    # unknown key rather than binding a course that no longer exists (which
    # failed the foreign key and 500ed inside the Canvas iframe).
    it 'refuses a launch once the key\'s course has been deleted' do
      course.destroy
      launch
      expect(response).to have_http_status(:unauthorized)
      expect(response).to render_template('lti_launch/launch_error')
    end

    # An instructor mistyping the secret is not an incident; a key we never
    # issued is.
    it 'reports the unexplainable refusals and stays quiet about the typo' do
      launch(sign(launch_params, secret: 'not-the-secret'))
      expect(Sentry).not_to have_received(:capture_message)
      launch(sign(launch_params('oauth_consumer_key' => 'never-issued')))
      expect(Sentry).to have_received(:capture_message)
    end

    # An unknown key is the one refusal reachable with no knowledge of any key,
    # so it is the one an unauthenticated loop could use to flood Sentry. The
    # test cache store is a null store, which the throttle treats as "cache
    # down, report everything", so these examples give it a real one.
    context 'when unknown keys keep arriving' do
      before { allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new) }

      def probe(env = {})
        params = sign(launch_params('oauth_consumer_key' => 'never-issued'))
        post '/lti/legacy/launch', params:, env:
      end

      it 'reports the first from an address and throttles the rest for an hour' do
        3.times { probe }
        expect(Sentry).to have_received(:capture_message).once
        travel_to((LtiLegacyLaunchesController::UNKNOWN_KEY_REPORT_INTERVAL + 1.minute).from_now) do
          probe
        end
        expect(Sentry).to have_received(:capture_message).twice
      end

      it 'throttles per address, so a probe from elsewhere is still reported' do
        probe
        probe('REMOTE_ADDR' => '203.0.113.7')
        expect(Sentry).to have_received(:capture_message).twice
      end

      # Only an unknown key is throttled: the other reported refusals need a
      # captured signature or a real secret, so they cannot be produced cheaply.
      it 'still reports every replay' do
        signed = sign(launch_params)
        3.times { launch(signed) }
        expect(Sentry).to have_received(:capture_message).twice
      end
    end
  end

  describe 'the feature gate' do
    it '404s when legacy launches are disabled' do
      allow(Features).to receive(:lti_legacy_launches?).and_return(false)
      launch
      expect(response).to have_http_status(:not_found)
    end

    it '404s when the Canvas integration is disabled' do
      allow(Features).to receive(:canvas_integration?).and_return(false)
      launch
      expect(response).to have_http_status(:not_found)
    end
  end
end
