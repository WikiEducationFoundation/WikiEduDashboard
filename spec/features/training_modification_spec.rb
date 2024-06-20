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

        expect(page).to have_content('Testing Library')
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

  describe 'TrainingCategory' do
    before do
      login_as(user, scope: :user)
      visit "/training/#{training_library.slug}"
    end

    it 'shows the "Create New Category" button' do
      expect(page).to have_selector('button.cat-create')
    end

    it 'creates a new category and verifies its creation' do
      find('button.cat-create').click

      fill_in 'title', with: 'Testing Category'
      fill_in 'description', with: 'This category is only created for testing purposes.'
      click_button 'Create'
      visit "/training/#{training_library.slug}"

      expect(page).to have_content('Testing Category')
      expect(page).to have_content('This category is only created for testing purposes.')
    end

    it 'displays validation errors for empty fields' do
      find('button.cat-create').click

      fill_in 'title', with: ''
      fill_in 'description', with: ''
      click_button 'Create'

      expect(page).to have_content('This field is required')
    end

    it 'prevents creating a category with a duplicate title' do
      find('button.cat-create').click

      fill_in 'title', with: 'Duplicate Category'
      fill_in 'description', with: 'First instance of this category.'
      click_button 'Create'
      visit "/training/#{training_library.slug}"

      expect(page).to have_content('Duplicate Category')
      expect(page).to have_content('First instance of this category.')

      find('button.cat-create').click
      fill_in 'title', with: 'Duplicate Category'
      fill_in 'description', with: 'Second instance of this category.'
      click_button 'Create'

      expect(page).to have_content('Category with this title already exists')
    end

    it 'creates a new category and then deletes it' do
      find('button.cat-create').click

      fill_in 'title', with: 'Testing Category'
      fill_in 'description', with: 'This category is only created for testing purposes.'
      click_button 'Create'

      visit "/training/#{training_library.slug}"

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
end
