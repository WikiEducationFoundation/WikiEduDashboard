# frozen_string_literal: true

require 'rails_helper'

def mock_and_stub_oauth_login
  OmniAuth.config.test_mode = true
  allow_any_instance_of(OmniAuth::Strategies::Mediawiki)
    .to receive(:callback_url).and_return('/users/auth/mediawiki/callback')
  OmniAuth.config.mock_auth[:mediawiki] = OmniAuth::AuthHash.new(
    provider: 'mediawiki',
    uid: '123456',
    info: { name: 'Ragesoss' },
    credentials: { token: 'foo', secret: 'bar' }
  )
  allow_any_instance_of(WikiApi).to receive(:get_user_id).and_return(234567)
end

describe 'logging in', type: :feature, js: true do
  # Capybara.server_port = 3333

  context 'without a stubbed OAuth flow' do
    it 'sends the user to log in on Wikipedia and allow the app' do
      # pending 'This started failing in CI.'

      OmniAuth.config.logger = Rails.logger

      VCR.use_cassette 'oauth' do
        visit '/'
        click_link 'Log in with Wikipedia'
        fill_in('wpName', with: ENV['test_user'])
        fill_in('wpPassword', with: ENV['test_user_password'])
        click_button 'Log in'
        expect(page).to have_button('Allow')
        # We can't go any further in the OAuth flow in test environment

        # Clear the browser logs now so all the Wikipedia JS warnings
        # don't get logged during test runs.
        page.driver.browser.manage.logs.get(:browser)
      end

      # pass_pending_spec
    end
  end

  context 'with a stubbed OAuth flow' do
    it 'sets first_login on the user' do
      mock_and_stub_oauth_login
      visit '/'
      click_link 'Log in with Wikipedia'
      expect(page).to have_content 'Log out'
      expect(User.last.first_login).not_to be_nil
    end

    it 'handles OAuth failure' do
      OmniAuth.config.test_mode = true
      allow_any_instance_of(OmniAuth::Strategies::Mediawiki)
        .to receive(:callback_url).and_return('/users/auth/mediawiki/callback')
      OmniAuth.config.mock_auth[:mediawiki] = OmniAuth::AuthHash.new(
        extra: { raw_info: { login_failed: true } }
      )
      visit '/training'
      click_link 'Log in'
      expect(page).to have_content 'Login Error'
    end
  end
end
