# frozen_string_literal: true
require 'rails_helper'

describe 'Super Admin user', type: :feature, js: true do
  before do
    page.current_window.resize_to(1920, 1080)
    page.driver.browser.url_blacklist = ['https://wikiedu.org']
  end

  before :each do
    super_admin = create( :admin,
                          id: 300)
    create(:special_users,
           value: { super_admin: super_admin.username,
                    classroom_program_manager: super_admin.username})

    login_as(super_admin, scope: :user)
  end

  describe 'visiting the admin dashboard' do
    it 'should see Settings button' do
      visit admin_index_path
      sleep 1
      expect(page).to have_content 'App Settings'
    end

    it 'should not see Settings button as not Super Admin' do
      simple_admin = create(:admin,
                            id: 200,
                            username: 'Ragesore')
      logout
      login_as(simple_admin, scope: :user)
      visit admin_index_path
      sleep 1
      expect(page).not_to have_content 'App Settings'
    end
  end

  describe 'changing app settings' do
    it 'should update Classroom program manager' do
      visit admin_index_path
      click_link('App Settings')

      expect(page).to have_content 'Special users'

      within '.special_users_form' do
        fill_in 'setting_special_users_classroom_program_manager', with: 'Tom Hanks'
        find('.button', visible: true).click
      end
      # Should we run checks after `visit`?
      visit settings_path
      sleep 1
      expect(page).to have_content 'Classroom program manager'
      expect(page).to have_field('setting_special_users_classroom_program_manager', :with => 'Tom Hanks')
    end

    it 'should add Special Users' do
      visit admin_index_path
      click_link('App Settings')

      expect(page).to have_content 'Special users'

      within '.special_users_form' do
        fill_in 'setting_new_setting', with: 'clasSroom Manager'
        fill_in 'setting_setting_value', with: 'Tom Hacks'
        find('.button', visible: true).click
      end

      visit settings_path
      sleep 1
      expect(page).to have_content 'Classroom manager'
      expect(page).to have_field('setting_special_users_classroom_manager', :with => 'Tom Hacks')

      # Add the same role again
      within '.special_users_form' do
        fill_in 'setting_new_setting', with: 'classRoom manager'
        fill_in 'setting_setting_value', with: 'Tom Hicks'
        find('.button', visible: true).click
      end
      expect(page).to have_content 'No changes were made'
      expect(page).to have_content 'Classroom manager'
      expect(page).to have_field('setting_special_users_classroom_manager', :with => 'Tom Hacks')
      expect(page).not_to have_field('setting_special_users_classroom_manager', :with => 'Tom Hicks')
    end

    it 'should delete Classroom program manager' do
      visit admin_index_path
      click_link('App Settings')

      expect(page).to have_content 'Special users'
      expect(page).to have_content 'Classroom program manager'

      within '.special_users_form' do
        click_link('classroom_program_manager')
        # within all('div.form-group').last do
        #   click_link('Delete')
        # end
      end

      expect(page).not_to have_content 'Classroom program manager'
    end
  end

  after do
    logout
  end
end
