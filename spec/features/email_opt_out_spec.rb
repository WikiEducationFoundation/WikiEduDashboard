# frozen_string_literal: true

require 'rails_helper'

describe 'email preferences opt out', type: :feature, js: true do
  let(:user) { create(:user) }
  let(:token) { user.email_preferences_token }
  let(:subject) { user.user_profile.reload.email_preferences['OverdueTrainingAlert'] }

  it 'returns does nothing if token is incorrect' do
    visit "/update_email_preferences/#{user.username}?type=OverdueTrainingAlert&token=wrong_token"
    expect(subject).to be_nil
    # Selenium does not implement #status_code
    # expect(page.status_code).to eq(401)
  end

  it 'updates the preferences if token is correct' do
    visit "/update_email_preferences/#{user.username}?type=OverdueTrainingAlert&token=#{token}"
    expect(subject).to eq(false)
  end
end
