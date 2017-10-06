# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/training_module"

DESIRED_TRAINING_MODULE_IDS = [2].freeze

describe 'Training', type: :feature, js: true do
  let(:user) { create(:user, id: 1) }
  let(:module_2) { TrainingModule.find(2) } # Policies and Guidelines module

  before do
    login_as(user, scope: :user)
    page.driver.browser.url_blacklist = ['https://www.youtube.com', 'https://upload.wikimedia.org']
  end

  describe 'root library' do
    library_names = TrainingLibrary.all.map(&:slug)
    it 'loads for a logged-in user' do
      visit '/training'
      library_names.each do |library_name|
        expect(page).to have_content library_name.humanize.titleize
      end
    end

    it 'loads for a logged-out user' do
      logout(:user)
      visit '/training'
      library_names.each do |library_name|
        expect(page).to have_content library_name.humanize.titleize
      end
    end

    after do
      login_as(user, scope: :user)
    end
  end

  describe 'libraries' do
    TrainingLibrary.all.each do |library|
      describe "'#{library.name}' library" do
        it 'renders the overview' do
          visit "/training/#{library.slug}"
          expect(page).to have_content library.name
        end
      end
    end

    it 'load for a logged out user' do
      logout(:user)
      first_library = TrainingLibrary.all[0]
      visit "/training/#{first_library.slug}"
      expect(page).to have_content first_library.name
    end

    after do
      login_as(user, scope: :user)
    end
  end

  describe 'module index page' do
    before do
      visit "/training/students/#{module_2.slug}"
    end

    it 'describes the module' do
      expect(page).to have_content module_2.name
      expect(page).to have_content 'Estimated time to complete'
      expect(page).to have_content module_2.estimated_ttc
    end

    it 'renders the table of contents' do
      expect(page).to have_content 'TABLE OF CONTENTS'
      expect(page).to have_content module_2.slides[0].title
      expect(page).to have_content module_2.slides[-1].title
    end

    it 'lets the user start the module' do
      click_link 'Start'
      slide_count = module_2.slides.count
      expect(page).to have_content "Page 1 of #{slide_count}"
      expect(TrainingModulesUsers.find_by(
               user_id: user.id,
               training_module_id: module_2.id
      )).not_to be_nil
    end

    it 'updates the last_slide_completed upon viewing a slide (not after clicking `next`)' do
      click_link 'Start'
      sleep 1.5
      tmu = TrainingModulesUsers.find_by(user_id: user.id, training_module_id: module_2.id)
      expect(tmu.last_slide_completed).to eq(module_2.slides.first.slug)
      click_link 'Next Page'
      sleep 1.5
      expect(tmu.reload.last_slide_completed).to eq(module_2.slides.second.slug)
    end

    it 'sets the module completed on viewing the last slide' do
      login_as(user, scope: :user)
      sleep 1
      click_link 'Start'
      tmu = TrainingModulesUsers.find_by(user_id: user.id, training_module_id: module_2.id)
      visit "/training/students/#{module_2.slug}/#{module_2.slides.last.slug}"
      sleep 2
      expect(tmu.reload.completed_at).to be_between(1.minute.ago, 1.minute.from_now)
    end

    it 'disables slides that have not been seen' do
      click_link 'Start'
      within('.training__slide__nav') { find('.hamburger').click }
      unseen_slide_link = find('.slide__menu__nav__dropdown li:last-child a')['disabled']
      expect(unseen_slide_link).not_to be_nil
    end

    it 'shows a 404 page for non-existent slides' do
      visit "/training/students/#{module_2.slug}/lol-not-a-real-slide"
      expect(page).to have_content 'Page not found'
    end

    it 'loads for a logged out user' do
      logout(:user)
      expect(page).to have_content 'TABLE OF CONTENTS'
      expect(page).to have_content module_2.slides[0].title
      expect(page).to have_content module_2.slides[-1].title
    end

    after do
      login_as(user, scope: :user)
    end
  end

  describe 'finish module button' do
    context 'logged in user' do
      it 'redirects to their dashboard' do
        login_as(user, scope: :user)
        sleep 1
        visit "/training/students/#{module_2.slug}/#{module_2.slides.last.slug}"
        sleep 1
        within '.training__slide__footer' do
          click_link 'Done!'
        end
        sleep 1
        expect(current_path).to eq(root_path)
      end
    end

    context 'logged out user' do
      it 'redirects to library index page' do
        logout(:user)
        visit "/training/students/#{module_2.slug}/#{module_2.slides.last.slug}"
        sleep 1
        within '.training__slide__footer' do
          click_link 'Done!'
        end
        expect(current_path).to eq('/training/students')
      end
    end
  end

  DESIRED_TRAINING_MODULE_IDS.each do |module_id|
    training_module = TrainingModule.find(module_id)
    describe "'#{training_module.name}' module" do
      training_module = TrainingModule.find(module_id)
      it 'lets the user go from start to finish' do
        go_through_module_from_start_to_finish(training_module)
      end
    end
  end
end

def go_through_module_from_start_to_finish(training_module)
  visit "/training/students/#{training_module.slug}"
  click_link 'Start'
  click_through_slides(training_module)
  sleep 1
  expect(TrainingModulesUsers.find_by(
    user_id: 1,
    training_module_id: training_module.id
  ).completed_at).not_to be_nil
end

def click_through_slides(training_module)
  slide_count = training_module.slides.count
  training_module.slides.each_with_index do |slide, i|
    check_slide_contents(slide, i, slide_count)
    unless i == slide_count - 1
      proceed_to_next_slide
      next
    end
    click_link 'Done!'
  end
end

def check_slide_contents(slide, slide_number, slide_count)
  expect(page).to have_content slide.title
  expect(page).to have_content "Page #{slide_number + 1} of #{slide_count}"
end

def proceed_to_next_slide
  button = page.first('button.ghost-button')
  find_correct_answer_by_trial_and_error unless button.nil?
  page.first('a.slide-nav.btn.btn-primary.icon-rt_arrow').trigger('click')
end

def find_correct_answer_by_trial_and_error
  (0..10).each do |current_answer|
    within('.training__slide') do
      all('input')[current_answer].click
    end
    click_button 'Check Answer'
    next_button = page.first('a.slide-nav.btn.btn-primary')
    break unless next_button['disabled'] == 'true'
  end
end
