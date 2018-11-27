# frozen_string_literal: true

require 'rails_helper'

describe 'settings', type: :feature, js: true do
  let(:super_admin) { create(:super_admin) }
  let(:user) { create(:user) }
  let(:special_user) { create(:user, username: 'specialuser') }

  before do
    login_as(super_admin, scope: :user)
    Setting.set_special_user('communications_manager', special_user.username)
    visit '/settings'
  end

  context 'for special users' do
    it 'adds a special user' do
      click_button 'Add Special User'
      fill_in('new_special_user', with: user.username)
      select 'communications_manager'
      find('form .button').click
      find('[value=confirm]').click
      sleep 1
      expect(SpecialUsers.is?(user, 'communications_manager')).to eq(true)
    end

    it 'removes a special user' do
      click_button 'Revoke Special User'
      click_button I18n.t(
        'settings.special_users.remove.revoke_button_confirm',
        username: special_user.username
      )
      sleep 1
      expect(SpecialUsers.is?(special_user, 'communications_manager')).to eq(false)
    end

    it 'shows an error for invalid user' do
      click_button 'Add Special User'
      fill_in('new_special_user', with: 'loliamnouser')
      select 'communications_manager'
      find('form .button').click
      find('[value=confirm]').click
      sleep 1
      expect(page).to have_content('not an existing user.')
    end
  end
end
