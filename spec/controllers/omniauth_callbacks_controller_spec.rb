# frozen_string_literal: true

require 'rails_helper'

describe OmniauthCallbacksController, type: :request do
  let(:user) { create(:user) }
  let(:auth_hash) do
    OmniAuth::AuthHash.new(
      provider: 'mediawiki',
      uid: user.username,
      info: { name: user.username }
    )
  end

  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:mediawiki] = auth_hash
    Rails.application.env_config['omniauth.auth'] = auth_hash
    allow(Features).to receive(:canvas_integration?).and_return(true)
    allow(UserImporter).to receive(:from_omniauth).and_return(user)
  end

  after { OmniAuth.config.test_mode = false }

  describe '#mediawiki — LTI return path' do
    # OmniAuth test mode bypasses the middleware that would normally
    # populate omniauth.params during the auth request phase, and our
    # test hits the callback URL directly. Inject the params via a
    # before-callback hook so the controller sees what production sees.
    def stub_omniauth_params(params)
      OmniAuth.config.before_callback_phase = ->(env) { env['omniauth.params'] = params }
    end

    after { OmniAuth.config.before_callback_phase = nil }

    context "when ltik came through omniauth.params" do
      it "rewrites omniauth.origin so after_sign_in returns to /lti?ltik=…" do
        stub_omniauth_params('ltik' => 'ltik-from-canvas')
        get '/users/auth/mediawiki/callback'
        expect(response).to redirect_to('/lti?ltik=ltik-from-canvas')
      end
    end

    context "without an ltik in omniauth.params" do
      it 'does not interfere with the normal sign-in redirect' do
        stub_omniauth_params({})
        get '/users/auth/mediawiki/callback'
        expect(response).to be_redirect
        # The normal flow may go anywhere reasonable (root, profile, etc.) —
        # the only assertion that matters is that we did NOT redirect to /lti.
        expect(response.location).not_to include('/lti')
      end
    end
  end
end
