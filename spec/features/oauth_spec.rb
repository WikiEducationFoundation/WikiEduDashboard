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
  before { mock_and_stub_oauth_login }

  it 'sets first_login on the user' do
    visit '/'
    click_link 'Log in with Wikipedia'
    expect(page).to have_content 'Log out'
    expect(User.last.first_login).not_to be_nil
  end
end
