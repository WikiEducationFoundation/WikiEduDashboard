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

  # For Training Library
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

  # For Training Module
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

  # For Training Slides
  describe 'TrainingSlide', type: :feature, js: true do
    let(:existing_slide1) do
      create(:training_slide, title: 'created-for-testing', slug: 'existing-slide1',
     wiki_page: 'Training modules/dashboard/slides/10306-be-polite')
    end
    let(:existing_slide2) do
      create(:training_slide, title: 'how-to-help', slug: 'existing-slide2',
     wiki_page: 'Training modules/dashboard/slides/12606-how-to-help')
    end
    let(:existing_slide3) do
      create(:training_slide, title: 'five-pillars', slug: 'existing-slide3',
     wiki_page: 'Training modules/dashboard/slides/10302-five-pillars')
    end
    let(:existing_slide4) do
      create(:training_slide, title: 'notability', slug: 'existing-slide4',
     wiki_page: 'Training modules/dashboard/slides/10313-notability')
    end

    before do
      login_as(user, scope: :user)
      visit '/training'
      click_button 'Switch to Edit Mode'
      sleep 1

      # Creating a category and adding module to it
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
      visit '/training/example-library/testing-module'
      existing_slide1
    end

    context 'when adding and removing a training slide' do
      let(:training_module) { TrainingModule.find_by(slug: 'testing-module') }

      it 'throws an error if slide with same slug but different wiki_page exists' do
        click_button 'Add Slide'

        fill_in 'Title', with: 'New Slide Title'
        fill_in 'Slug', with: 'existing-slide1'
        fill_in 'wiki_page', with: 'Training modules/dashboard/slides/10801-welcome-new-editor'
        click_button 'Add'

        expect(page).to have_content(I18n.t('training.validation.slide_slug_already_exist'))
      end

      it 'throws an error if slide with same slug
          and same wiki_page exists but is already in the training module' do
        click_button 'Add Slide'
        training_module.slide_slugs << existing_slide1.slug
        training_module.save

        fill_in 'Title', with: 'New Slide Title'
        fill_in 'Slug', with: 'existing-slide1'
        fill_in 'wiki_page', with: 'Training modules/dashboard/slides/10306-be-polite'
        click_button 'Add'

        expect(page).to have_content(I18n.t('training.validation.slide_already_exist'))
      end

      it 'adds the slide if slide with same slug and
          same wiki_page exists but is not in the training module' do
        click_button 'Add Slide'

        fill_in 'Title', with: 'New Slide Title'
        fill_in 'Slug', with: 'existing-slide1'
        fill_in 'wiki_page', with: 'Training modules/dashboard/slides/10306-be-polite'
        click_button 'Add'

        expect(training_module.reload.slide_slugs).to include('existing-slide1')
        expect(page).to have_content(existing_slide1.title)
      end

      it 'adding a new slide with invalid wikipage' do
        click_button 'Add Slide'
        fill_in 'Title', with: 'New Slide Title'
        fill_in 'Slug', with: 'new-slide-slug'
        fill_in 'wiki_page', with: 'anyInvalidWikipage'
        click_button 'Add'

        expect(page).to have_content('Wikipage not found')
      end

      it 'removes the slide from the training module' do
        # Adding the slide to the module
        training_module.slide_slugs << existing_slide1.slug
        training_module.save
        expect(training_module.reload.slide_slugs).to include('existing-slide1')

        # Removing the slide
        visit '/training/example-library/testing-module'
        click_button 'Remove Slide'
        expect(page).to have_selector('.program-description', count: 1)
        first('.program-description').click
        click_button 'Remove'

        expect(training_module.reload.slide_slugs).not_to include('existing-slide1')
      end
    end

    context 'when reordering slides' do
      let(:training_module) { TrainingModule.find_by(slug: 'testing-module') }

      before do
        # Make sure the slides are in the database
        existing_slide1
        existing_slide2
        existing_slide3
        existing_slide4
        # Adding the slides to the module
        training_module.slide_slugs = [
          existing_slide1.slug,
          existing_slide2.slug,
          existing_slide3.slug,
          existing_slide4.slug
        ]
        training_module.save
        visit '/training/example-library/testing-module'
      end

      it 'allows reordering of slides' do
        click_button I18n.t('training.change_order')
        expect(page).to have_content('Change Order')

        # Find the slide elements
        slides = all('.program-description')

        # Move the second slide to the bottom
        target = slides.last
        source = slides[1]
        source.drag_to(target)

        click_button 'Save'
        visit '/training/example-library/testing-module'

        # Verify the new order of slides
        training_module.reload
        expect(training_module.slide_slugs).to eq([existing_slide1.slug,
                                                   existing_slide3.slug,
                                                   existing_slide4.slug,
                                                   existing_slide2.slug])
      end
    end
  end
end
