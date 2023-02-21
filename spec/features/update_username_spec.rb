# frozen_string_literal: true

require 'rails_helper'

describe 'Update username controller', type: :feature, js: true do
  let!(:user) { create(:user) }

  before do
    login_as user
  end

  context 'Update Username page' do
    it 'checks if page is visited' do
      visit '/update_username'
      expect(page).to have_content('Enter Username to update')
    end

    it 'visits and enter updated username' do
      VCR.use_cassette('update_username') do
        create(:user, id: 500, username: 'Ragesoss')
        new_username = 'New Username'
        User.find(500).update_attribute(:username, new_username)
        visit '/update_username'
        fill_in('username', with: new_username)
        click_button 'Update Username'
        expect(User.find(500).username).to eq(new_username)
      end
    end
  end
end
