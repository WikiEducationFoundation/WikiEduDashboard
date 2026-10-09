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

    it 'previews the notice as rendered HTML before it is enabled' do
      click_button 'Update Site Notice'
      fill_in('site_notice', with: 'See the <a href="https://example.org">status page</a>.')
      within('.site-notice-preview .notification.sitenotice') do
        expect(page).to have_link('status page', href: 'https://example.org')
      end
    end
  end

  context 'when a long notice is already saved' do
    let(:long_notice) do
      'The Dashboard will be read-only on <b>Saturday</b> from 14:00 to 18:00 UTC while we ' \
        'upgrade our servers. Course statistics will not update during this window, and new ' \
        'enrollments will be paused. See the <a href="https://example.org">status page</a> ' \
        'for updates.<br>Questions? Contact <a href="mailto:help@example.org">helpdesk</a>. ' \
        'If you are running an edit-a-thon that weekend, please plan accordingly.'
    end

    before do
      Setting.create!(key: 'site_notice', value: { 'message' => long_notice, 'status' => false })
      visit '/settings'
    end

    it 'sizes the textarea to show the whole notice when the editor opens' do
      click_button 'Update Site Notice'
      expect(page).to have_field('site_notice', with: long_notice)
      heights = page.evaluate_script(<<~JS)
        (() => {
          const textarea = document.getElementById('site_notice');
          return [textarea.clientHeight, textarea.scrollHeight];
        })()
      JS
      expect(heights[0]).to be >= heights[1]
    end
  end
end
