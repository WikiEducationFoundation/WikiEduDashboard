require 'rails_helper'
require "#{Rails.root}/lib/training_module"

def check_slide_contents(slide, slide_number, slide_count)
  expect(page).to have_content training_module.slides[slide_number].title
  expect(page).to have_content "Page #{slide_number + 1} of #{slide_count}"
  pp "slide #{slide_number} looks good"
end

def proceed_to_next_slide
  button = page.first('button.ghost-button')
  find_correct_answer_by_trial_and_error unless button.nil?
  pp "ready to move on"
  click_link 'Next Page'
end

def find_correct_answer_by_trial_and_error
  correct_answer_found = false
  (1..10).each do |current_answer|
    pp "trying answer #{current_answer}"
    page.all('input')[current_answer].click
    click_button 'Check Answer'
    next_button = page.first('a.slide-nav.btn.btn-primary')
    return unless next_button['disabled'] == 'true'
  end
end

describe 'A training module', type: :feature, js: true do
  let(:cohort) { create(:cohort) }
  let(:user)   { create(:user, id: 1) }
  let(:training_module) { TrainingModule.find(2) } # Policies and Guidelines module

  before do
    login_as(user, scope: :user)
    Capybara.current_driver = :selenium
  end

  describe 'index page' do
    before do
      visit "/training/students/#{training_module.slug}"
    end

    it 'describes the module' do
      expect(page).to have_content training_module.name
      expect(page).to have_content 'Estimated time to complete'
      expect(page).to have_content training_module.estimated_ttc
    end

    it 'renders the table of contents' do
      expect(page).to have_content 'TABLE OF CONTENTS'
      expect(page).to have_content training_module.slides[0].title
      expect(page).to have_content training_module.slides[-1].title
    end

    it 'lets the user start the module' do
      click_link 'Start'
      slide_count = training_module.slides.count
      #expect(page).to have_content "Page 1 of #{slide_count}"
      expect(TrainingModulesUsers.find_by(
        user_id: user.id,
        training_module_id: training_module.id
      )).not_to be_nil
    end

    it 'disables slides that have not been seen' do
      click_link 'Start'
      find('.training__slide__nav').click
      unseen_slide_link = find('.slide__menu__nav__dropdown li:nth-child(3) a')
      expect(unseen_slide_link['disabled']).to eq('true')
    end
  end

  describe 'slide sequence' do
    it 'lets the user go from start to finish' do
      slide_count = training_module.slides.count

      visit "/training/students/#{training_module.slug}"
      click_link 'Start'
      training_module.slides.each_with_index do |slide, i|
        pp "slide #{i}"
        check_slide_contents(slide, i, slide_count)
        next if i == slide_count - 1 # Nowhere to go after the last slide

        proceed_to_next_slide
      end
    end
  end
end
