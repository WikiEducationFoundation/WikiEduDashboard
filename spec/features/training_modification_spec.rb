# frozen_string_literal: true

require 'rails_helper'

describe 'TrainingContent', type: :feature, js: true do
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }
  let(:training_library) do
    create(:training_library,
           name: 'Example-Library',
           slug: 'example-library',
           introduction: 'For Testing')
  end

  before(:all) do
    TrainingModule.load_all
  end

  describe 'TrainingLibrary' do
    context 'when logged in as an admin' do
      before do
        login_as(admin, scope: :user)
        visit '/training'
        click_button 'Switch to Edit Mode'
      end

      it 'creates a new training library and verifies its creation' do
        click_button 'Create New Library'

        fill_in 'Library Name', with: 'Testing Library'
        fill_in 'Library Slug', with: 'testing-library'
        fill_in 'Library Introduction', with: 'This library is only created for testing purposes.'

        click_button 'Create'

        expect(page).to have_content('Testing Library')
      end

      it 'prevents the creation of two libraries with the same slug' do
        # Create the first library
        click_button 'Create New Library'
        fill_in 'Library Name', with: 'First Testing Library'
        fill_in 'Library Slug', with: 'duplicate-slug'
        fill_in 'Library Introduction', with: 'First instance of library creation.'
        click_button 'Create'

        # Try to create a second library with the same slug
        click_button 'Create New Library'
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
        click_button 'Switch to Edit Mode'
      end

      it 'does not show the "Create Training Library" button' do
        expect(page).not_to have_content('Create New Library')
      end
    end
  end

  describe 'TrainingCategory' do
    before do
      login_as(user, scope: :user)
      visit '/training'
      click_button 'Switch to Edit Mode'
      visit "/training/#{training_library.slug}"
    end

    it 'creates a new category and verifies its creation' do
      visit "/training/#{training_library.slug}"
      click_button 'Create New Category'

      fill_in 'title', with: 'Testing Category'
      fill_in 'description', with: 'This category is only created for testing purposes.'
      click_button 'Create'

      expect(page).to have_content('Testing Category')
      expect(page).to have_content('This category is only created for testing purposes.')
    end

    it 'displays validation errors for empty fields' do
      visit "/training/#{training_library.slug}"
      click_button 'Create New Category'

      fill_in 'title', with: ''
      fill_in 'description', with: ''
      click_button 'Create'

      expect(page).to have_content('This field is required')
    end

    it 'prevents creating a category with a duplicate title' do
      visit "/training/#{training_library.slug}"
      click_button 'Create New Category'

      fill_in 'title', with: 'Duplicate Category'
      fill_in 'description', with: 'First instance of this category.'
      click_button 'Create'

      expect(page).to have_content('Duplicate Category')
      expect(page).to have_content('First instance of this category.')

      click_button 'Create New Category'
      fill_in 'title', with: 'Duplicate Category'
      fill_in 'description', with: 'Second instance of this category.'
      click_button 'Create'

      expect(page).to have_content('Category with this title already exists')
    end

    it 'creates a new category and then deletes it' do
      visit "/training/#{training_library.slug}"
      click_button 'Create New Category'

      fill_in 'title', with: 'Testing Category'
      fill_in 'description', with: 'This category is only created for testing purposes.'
      click_button 'Create'

      expect(page).to have_content('Testing Category')
      expect(page).to have_content('This category is only created for testing purposes.')

      # Delete this newly created category as initially it has no modules in it
      within find('li', text: 'Testing Category') do
        expect(page).to have_selector('a.button.danger', text: I18n.t('training.delete_category'))
        find('a.button.danger', text: I18n.t('training.delete_category')).click
      end

      # Confirm the deletion
      page.driver.browser.switch_to.alert.accept

      expect(page).not_to have_content('Testing Category')
      expect(page).not_to have_content('This category is only created for testing purposes.')
    end
  end

  describe 'TrainingModule' do
    before do
      login_as(user, scope: :user)
      visit '/training'
      click_button 'Switch to Edit Mode'
      visit "/training/#{training_library.slug}"
    end

    it 'add module after creating a category' do
      visit "/training/#{training_library.slug}"
      click_button 'Create New Category'

      fill_in 'title', with: 'Testing Category'
      fill_in 'description', with: 'This category is only created for testing purposes.'
      click_button 'Create'
      expect(page).to have_content('Testing Category')

      click_link 'Add Module'
      fill_in 'Module Name', with: 'Testing Module'
      fill_in 'Module Slug', with: 'testing-module'
      fill_in 'Module Description', with: 'This module is only created for testing purposes.'
      click_button 'Add'
      expect(page).to have_content('Testing Module')
      expect(page).to have_content('This module is only created for testing purposes.')
    end

    it 'transfers modules between categories' do
      visit "/training/#{training_library.slug}"
      
      # Creating source category
      click_button 'Create New Category'
      fill_in 'title', with: 'Source Category'
      fill_in 'description', with: 'This is my source category.'
      click_button 'Create'
      expect(page).to have_content('Source Category')

      # Adding module in source category
      click_link 'Add Module'
      fill_in 'Module Name', with: 'Module 1'
      fill_in 'Module Slug', with: 'module1'
      fill_in 'Module Description', with: 'This module is only created for testing purposes.'
      click_button 'Add'
      expect(page).to have_content('Module 1')

      # Creating destination category
      click_button 'Create New Category'
      fill_in 'title', with: 'Destination Category'
      fill_in 'description', with: 'This is my destination category.'
      click_button 'Create'
      expect(page).to have_content('Destination Category')

      click_button 'Transfer Module'
      expect(page).to have_selector('.program-description', count: 1)

      # Select source category
      first('.program-description').click
      click_button 'Next'

      # Select module to transfer
      first('.program-description').click
      click_button 'Next'

      # Select destination category
      expect(page).to have_selector('.program-description', count: 1)
      first('.program-description').click
      click_button 'Transfer'

      # Verify expected changes
      within find('.training__categories') do
        within find('li', text: 'Source Category') do
          expect(page).not_to have_content('Module 1')
        end
    
        within find('li', text: 'Destination Category') do
          expect(page).to have_content('Module 1')
        end
      end
    end
  end
end
