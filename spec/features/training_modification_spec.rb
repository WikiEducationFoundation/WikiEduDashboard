# frozen_string_literal: true

require 'rails_helper'

describe 'TrainingLibrary', type: :feature, js: true do
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }

  context 'when logged in as an admin' do
    before do
      login_as(admin, scope: :user)
      visit '/training'
    end

    it 'shows the "Create Training Library" button' do
      expect(page).to have_selector('button.lib-create')
    end

    it 'creates a new training library and verifies its creation' do
      expect(page).to have_selector('button.lib-create')

      find('button.lib-create').click

      fill_in 'Library Name', with: 'Testing Library'
      fill_in 'Library Slug', with: 'testing-library'
      fill_in 'Library Introduction', with: 'This library is only created for testing purposes.'

      click_button 'Create'

      visit '/training/testing-library'
      expect(page).to have_content('Testing Library')
      expect(page).to have_content('This library is only created for testing purposes.')
    end

    it 'prevents the creation of two libraries with the same slug' do
      expect(page).to have_selector('button.lib-create')

      # Create the first library
      find('button.lib-create').click
      fill_in 'Library Name', with: 'First Testing Library'
      fill_in 'Library Slug', with: 'duplicate-slug'
      fill_in 'Library Introduction', with: 'First instance of library creation.'
      click_button 'Create'

      # Try to create a second library with the same slug
      visit '/training'
      find('button.lib-create').click
      fill_in 'Library Name', with: 'Second Testing Library'
      fill_in 'Library Slug', with: 'duplicate-slug'
      fill_in 'Library Introduction', with: 'Second instance of library creation.'
      click_button 'Create'

      # Verify the error message
      expect(page).to have_content('Slug has already been taken')

      # Verify the second library has not been created
      visit '/training/duplicate-slug'
      expect(page).to have_content('First Testing Library')
      expect(page).to have_content('First instance of library creation.')
      expect(page).not_to have_content('Second Testing Library')
      expect(page).not_to have_content('Second instance of library creation.')
    end
  end

  context 'when logged in as a regular user' do
    before do
      login_as(user, scope: :user)
      visit '/training'
    end

    it 'does not show the "Create Training Library" button' do
      expect(page).not_to have_selector('button.lib-create')
    end
  end
end
