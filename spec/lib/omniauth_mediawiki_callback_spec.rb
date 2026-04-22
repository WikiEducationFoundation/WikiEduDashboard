# frozen_string_literal: true

require 'rails_helper'

# Regression guard for the omniauth-oauth / Rack compatibility of the
# MediaWiki OAuth callback phase.
#
# In April 2026, omniauth-oauth 1.2.0 paired with Rack 3 broke login in
# production: the gem's `callback_phase` called `request["oauth_verifier"]`,
# and Rack 3 removed `Rack::Request#[]`. The existing feature specs in
# spec/features/oauth_spec.rb all run with `OmniAuth.config.test_mode = true`,
# which skips the real callback phase, so they sailed past the bug.
#
# This spec exercises the real callback phase with a real Rack::Request,
# stopping at the upstream access-token exchange. If the gem regresses on
# Rack compatibility, the expectation below will fail with NoMethodError
# on Rack::Request instead of the sentinel.
describe 'MediaWiki OAuth callback phase' do
  StubbedAccessTokenExchange = Class.new(StandardError)

  let(:rack_app) { ->(_env) { [200, {}, ['ok']] } }
  let(:strategy) do
    OmniAuth::Strategies::Mediawiki.new(
      rack_app, 'consumer_key', 'consumer_secret',
      client_options: { site: 'https://en.wikipedia.org' }
    )
  end
  let(:env) do
    Rack::MockRequest.env_for(
      '/users/auth/mediawiki/callback?oauth_verifier=v&oauth_token=t',
      'rack.session' => {
        'oauth' => {
          'mediawiki' => {
            'callback_confirmed' => true,
            'request_token' => 'request_token_value',
            'request_secret' => 'request_secret_value'
          }
        }
      }
    )
  end

  before do
    strategy.instance_variable_set(:@env, env)
    allow_any_instance_of(::OAuth::RequestToken)
      .to receive(:get_access_token).and_raise(StubbedAccessTokenExchange)
  end

  it 'reads oauth_verifier from the callback request via a Rack-compatible API' do
    expect { strategy.callback_phase }.to raise_error(StubbedAccessTokenExchange)
  end
end
