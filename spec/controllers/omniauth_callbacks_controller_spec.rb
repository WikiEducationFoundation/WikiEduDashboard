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
    context "with a stashed ltik in session" do
      before do
        # Prime the session by hitting /lti/connect_course at top-level.
        # That action stashes the ltik so the OAuth callback can read it.
        get '/lti/connect_course', params: { ltik: 'ltik-from-canvas' }
      end

      it "rewrites omniauth.origin so after_sign_in returns to /lti?ltik=…" do
        get '/users/auth/mediawiki/callback'
        expect(response).to redirect_to('/lti?ltik=ltik-from-canvas')
        expect(session['ltik']).to be_nil
      end
    end

    context "without a stashed ltik" do
      it 'does not interfere with the normal sign-in redirect' do
        get '/users/auth/mediawiki/callback'
        expect(response).to be_redirect
        # The normal flow may go anywhere reasonable (root, profile, etc.) —
        # the only assertion that matters is that we did NOT redirect to /lti.
        expect(response.location).not_to include('/lti')
      end
    end
  end
end
