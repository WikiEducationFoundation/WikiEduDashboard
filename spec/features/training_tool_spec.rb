# frozen_string_literal: true

require 'rails_helper'

DESIRED_TRAINING_MODULES = [{ slug: 'sandboxes-talk-watchlists' }].freeze

describe 'Training', type: :feature, js: true do
  let(:user) { create(:user, id: 1) }
  let(:module_2) { TrainingModule.find_by(slug: 'sandboxes-talk-watchlists') }
  let(:new_instructor_orientation_module) do
    TrainingModule.find_by(slug: 'new-instructor-orientation')
  end

  before(:all) do
    TrainingModule.load_all
  end

  before do
    login_as(user, scope: :user)
  end

  describe 'root library' do
    library_names = TrainingLibrary.all.reject(&:exclude_from_index?).map(&:name)
    after do
      login_as(user, scope: :user)
    end

    it 'loads for a logged-in user' do
      visit '/training'
      library_names.each do |library_name|
        expect(page).to have_content library_name
      end
    end

    it 'loads for a logged-out user' do
      logout(:user)
      visit '/training'
      library_names.each do |library_name|
        expect(page).to have_content library_name
      end
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

    after do
      login_as(user, scope: :user)
    end

    it 'load for a logged out user' do
      logout(:user)
      first_library = TrainingLibrary.all[0]
      visit "/training/#{first_library.slug}"
      expect(page).to have_content first_library.name
    end
  end

  describe 'module index page' do
    before do
      TrainingSlide.load
      visit "/training/students/#{module_2.slug}"
    end

    after do
      login_as(user, scope: :user)
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
      sleep 1
      tmu = TrainingModulesUsers.find_by(user_id: user.id, training_module_id: module_2.id)
      expect(tmu.last_slide_completed).to eq(module_2.slides.first.slug)
      click_link 'Next Page'
      sleep 1
      expect(tmu.reload.last_slide_completed).to eq(module_2.slides.second.slug)
    end

    it 'allows for navigation with the left and right buttons' do
      click_link 'Start'
      expect(page).to have_content('Page 1 of')
      find('html').native.send_keys :right
      expect(page).to have_content('Page 2 of')
      find('html').native.send_keys :left
      expect(page).to have_content('Page 1 of')
    end

    it 'sets the module completed on viewing the last slide' do
      login_as(user, scope: :user)
      click_link 'Start'
      tmu = TrainingModulesUsers.find_by(user_id: user.id, training_module_id: module_2.id)
      visit "/training/students/#{module_2.slug}/#{module_2.slides.last.slug}"
      expect(page).to have_link 'Done!'
      click_link 'Explore'
      expect(page).to have_content 'Active Courses'
      expect(tmu.reload.completed_at).to be_between(1.minute.ago, 1.minute.from_now)
    end

    it 'sets the new_instructor_orientation completed on viewing the last slide and promotes the user to instructor if applicable' do # rubocop:disable Layout/LineLength
      visit "/training/students/#{new_instructor_orientation_module.slug}"
      click_link 'Start'
      tmu = TrainingModulesUsers.find_by(user_id: user.id,
                                         training_module_id: new_instructor_orientation_module.id)
      visit "/training/students/#{new_instructor_orientation_module.slug}
                                /#{new_instructor_orientation_module.slides.last.slug}"
      expect(page).to have_link 'Done!'
      click_link 'Done!'
      expect(page).to have_link 'Create Course'
      expect(tmu.reload.completed_at).to be_between(1.minute.ago, 1.minute.from_now)
      expect(user.reload.permissions).to eq(User::Permissions::INSTRUCTOR)
    end

    it 'disables slides that have not been seen' do
      click_link 'Start'
      within('.training__slide__nav') { find('.hamburger').click }
      unseen_slide_link = find('.slide__menu__nav__dropdown li:last-child a')['disabled']
      expect(unseen_slide_link).not_to be_nil
    end

    it 'shows slide does not exist for non-existent slides' do
      visit "/training/students/#{module_2.slug}/lol-not-a-real-slide"
      expect(page).to have_content 'slide does not exist'
    end

    it 'loads for a logged out user' do
      logout(:user)
      expect(page).to have_content 'TABLE OF CONTENTS'
      expect(page).to have_content module_2.slides[0].title
      expect(page).to have_content module_2.slides[-1].title
    end
  end

  describe 'display message if none available' do
    context 'when wiki_education mode' do
      let(:url) { '/reload_trainings?module=all' }

      before do
        allow(Features).to receive(:wiki_ed?).and_return(true)
        TrainingLibrary.delete_all
        visit '/training'
      end

      it 'displays proper message in wiki_ed mode' do
        expect(page.html)
          .to include(I18n.t('training.no_training_library_records_wiki_ed_mode',
                             url:))
      end

      it 'includes a link' do
        expect(page).to have_link(href: url)
      end
    end

    context 'when in non wiki_education mode' do
      before do
        allow(Features).to receive(:wiki_ed?).and_return(false)
        TrainingLibrary.delete_all
        visit '/training'
      end

      it 'displays proper message in non wiki_ed mode' do
        expect(page.html)
          .to include(I18n.t('training.no_training_library_records_non_wiki_ed_mode'))
      end
    end
  end

  describe 'display of a search form' do
    before do
      TrainingSlide.load
      visit '/training'
    end

    it 'displays a simple search input' do
      expect(page).to have_field('search_training')
    end

    it 'displays search results' do
      fill_in('search_training', with: 'cnn')
      click_button('training_search_button')
      expect(page).to have_content('Policies and guidelines: basic overview')
    end
  end

  describe 'finish module button' do
    before do
      TrainingSlide.load
      visit "/training/students/#{module_2.slug}"
    end

    context 'logged in user' do
      it 'redirects to their dashboard' do
        login_as(user, scope: :user)
        visit "/training/students/#{module_2.slug}/#{module_2.slides.last.slug}"
        expect(page).to have_link 'Done!'
        within '.training__slide__footer' do
          click_link 'Done!'
        end
        expect(page).to have_content 'Welcome!'
        expect(page).to have_current_path(root_path)
      end
    end

    context 'logged out user' do
      it 'redirects to library index page' do
        click_link 'Log out'
        expect(page).to have_content 'Signed out successfully.'
        visit "/training/students/#{module_2.slug}/#{module_2.slides.last.slug}"
        expect(page).to have_link 'Done!'
        within '.training__slide__footer' do
          click_link 'Done!'
        end
        expect(page).to have_content 'Student Training Modules'
        expect(page).to have_current_path('/training/students')
      end
    end
  end

  describe 'lets the user go from start to finish' do
    before do
      TrainingSlide.load
    end

    DESIRED_TRAINING_MODULES.each do |module_slug|
      it "'#{module_slug[:slug]}' module" do
        training_module = TrainingModule.find_by(module_slug)
        go_through_module_from_start_to_finish(training_module)
      end
    end
  end
end

def go_through_module_from_start_to_finish(training_module)
  visit "/training/students/#{training_module.slug}"
  click_link 'Start'
  click_through_slides(training_module)
  expect(page).not_to have_link 'Done!'
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
  if page.has_selector?('.alert-box-container', wait: 0)
    within('.alert-box-container') do
      find('.alert-button').click
    end
  end
  button = page.first('button.ghost-button', minimum: 0)
  find_correct_answer_by_trial_and_error unless button.nil?
  page.first('a.slide-nav.btn.btn-primary.next-button').click
end

def find_correct_answer_by_trial_and_error
  10.times do |current_answer|
    within('.training__slide') do
      all('input')[current_answer].click
    end
    click_button 'Check Answer'
    next_button = page.first('a.slide-nav.btn.btn-primary')
    break if next_button['disabled'].nil?
  end
end
