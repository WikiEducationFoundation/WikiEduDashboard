# frozen_string_literal: true

require 'rails_helper'

describe 'settings', type: :feature, js: true do
  let(:super_admin) { create(:super_admin) }
  let(:user) { create(:user) }
  let(:special_user) { create(:user, username: 'specialuser') }

  before do
    login_as(super_admin, scope: :user)
    SpecialUsers.set_user('communications_manager', special_user.username)
    visit '/settings'
  end

  context 'for special users' do
    it 'adds a special user' do
      click_button 'Add Special User'
      fill_in('new_special_user', with: user.username)
      find('#specialUserPosition').click
      within '#specialUserPosition' do
        all('div', text: 'communications_manager')[2].click
      end
      click_button 'Submit'
      find('[value=confirm]').click
      expect(page).to have_content('was upgraded')
      expect(SpecialUsers.is?(user, 'communications_manager')).to eq(true)
    end

    it 'removes a special user' do
      click_button 'Revoke Special User'
      click_button I18n.t(
        'settings.special_users.remove.revoke_button_confirm',
        username: special_user.username
      )
      expect(page).to have_content('was removed')
      expect(SpecialUsers.is?(special_user, 'communications_manager')).to eq(false)
    end

    it 'shows an error for invalid user' do
      click_button 'Add Special User'
      fill_in('new_special_user', with: 'loliamnouser')
      find('#specialUserPosition').click
      within '#specialUserPosition' do
        all('div', text: 'communications_manager')[2].click
      end
      click_button 'Submit'
      find('[value=confirm]').click
      expect(page).to have_content('not an existing user.')
    end
  end

  describe 'for default campaign' do
    it 'allows updating the default campaign slug' do
      click_button 'Update Default Campaign'
      fill_in('default_campaign_slug', with: 'new-default-campaign-slug')
      click_button 'Submit'
      expect(page).to have_content('new-default-campaign-slug')
    end
  end

  describe 'for Salesforce credentials' do
    it 'allows updating the password and token' do
      click_button 'Update Salesforce Credentials'
      fill_in('salesforce_password', with: 'password')
      fill_in('salesforce_token', with: 'token')
      click_button 'Submit'
      expect(page).not_to have_content('Submit')
    end
  end

  describe 'for admins' do
    it 'allows adding and removing a admin rights' do
      expect(page).not_to have_content(user.username)
      click_button 'Add Admin'
      fill_in('new_admin_name', with: user.username)
      click_button 'Submit'
      click_button 'Grant admin'
      expect(page).to have_content(user.username)
    end
  end
end
