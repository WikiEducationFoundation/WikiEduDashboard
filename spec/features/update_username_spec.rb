# frozen_string_literal: true

require 'rails_helper'

describe 'Update username controller', type: :feature, js: true do
  let!(:user) { create(:user, id: 500, username: 'Temp') }

  before do
    login_as user
  end

  context 'Update Username page' do
    it 'visits and enter updated username' do
      VCR.use_cassette('update_username') do
        create(:user, id: 1, username: 'Old Username', global_id: '14093230')
        new_username = 'Ragesock'
        visit '/update_username'
        fill_in('username', with: new_username)
        click_button 'update_username'
        expect(User.find(1).username).to eq(new_username)
      end
    end
  end
end
