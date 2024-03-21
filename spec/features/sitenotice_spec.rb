# frozen_string_literal: true

require 'rails_helper'

describe 'sitenotice', type: :feature, js: true do
  let(:super_admin) { create(:super_admin) }

  before do
    # Delete the specific key from cache before each test
    Rails.cache.delete('site_notice')
    login_as(super_admin, scope: :user)
    visit '/settings'
  end

  context 'Updating the sitenotice' do
    let(:notice) { 'NOTICE: The system will go down for maintenance soon.' }

    it 'Display sitenotice because it is enabled' do
      click_button 'Update Site Notice'
      fill_in('site_notice', with: notice)
      click_button 'Submit'
      click_button 'Enable'
      visit root_path
      expect(first('.notification.sitenotice')).to have_content notice
    end

    it 'Does not display sitenotice because it is disabled' do
      click_button 'Update Site Notice'
      fill_in('site_notice', with: notice)
      click_button 'Submit'
      click_button 'Enable'
      click_button 'Disable'
      visit root_path
      expect(first('.notification', minimum: 0)).to be_nil
    end
  end
end
