# frozen_string_literal: true

require 'rails_helper'

describe 'Update username controller', type: :feature, js: true do
  let(:user) { create(:user, username: 'Temp') }

  before do
    login_as user
  end

  context 'it visits /update_username and' do
    it 'enter updated username' do
      VCR.use_cassette('update_username') do
        ## This global ID(14093230) belongs to user 'Ragesock'
        create(:user, username: 'Old Username', global_id: '14093230')
        new_username = 'Ragesock'
        visit '/update_username'
        fill_in('username', with: new_username)
        click_button 'update_username'
        expect(User.find_by(global_id: '14093230').username).to eq(new_username)
        expect(page).to have_content(I18n.t('update_username.username_updated'))
      end
    end
    it 'enter wrong username' do
      VCR.use_cassette('update_username') do
        create(:user, username: 'Old Username', global_id: '14093230')
        new_username = 'Ragesocs'
        visit '/update_username'
        fill_in('username', with: new_username)
        click_button 'update_username'
        expect(page).to have_content(I18n.t('update_username.not_found'))
      end
    end
    it 'and do not enter username' do
      VCR.use_cassette('update_username') do
        visit '/update_username'
        fill_in('username', with: '')
        click_button 'update_username'
        expect(page).to have_content(I18n.t('update_username.empty_username'))
      end
    end
  end
end
