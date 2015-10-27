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
  before do
    create(:cohort)
    user = create(:user,
                  id: 1)
    login_as(user, scope: :user)
    Capybara.current_driver = :selenium
  end

  let(:training_module) { TrainingModule.all[0] }

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
