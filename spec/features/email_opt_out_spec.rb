# frozen_string_literal: true

require 'rails_helper'

describe 'email preferences opt out', type: :feature, js: true do
  let(:user) { create(:user) }
  let(:token) { user.email_preferences_token }

  it 'returns a 401 if token is incorrect' do
    visit "/update_email_preferences/#{user.username}?type=OverdueTrainingAlert&token=wrong_token"
    expect(user.user_profile.reload.email_preferences['OverdueTrainingAlert']).to be_nil
    expect(page.status_code).to eq(401)
  end

  it 'updates the preferences if token is correct' do
    visit "/update_email_preferences/#{user.username}?type=OverdueTrainingAlert&token=#{token}"
    expect(user.user_profile.reload.email_preferences['OverdueTrainingAlert']).to eq(false)
  end
end
