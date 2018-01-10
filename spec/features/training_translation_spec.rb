# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/training_module"

describe 'Training Translations', type: :feature, js: true do
  let(:basque_user) { create(:user, id: 2, username: 'ibarra', locale: 'eu') }

  before do
    page.driver.browser.url_blacklist = ['https://www.youtube.com', 'https://upload.wikimedia.org']
    allow(Features).to receive(:wiki_trainings?).and_return(true)
    allow(TrainingSlide).to receive(:wiki_base_page).and_return('Training modules/dashboard/slides-test')
    allow(TrainingLibrary).to receive(:wiki_base_page).and_return('Training modules/dashboard/libraries-test')
    allow(TrainingModule).to receive(:wiki_base_page).and_return('Training modules/dashboard/modules-test')
    allow(TrainingBase).to receive(:base_path).and_return('none')
    no_yaml = "#{Rails.root}/training_content/none/*.yml"
    allow(TrainingSlide).to receive(:path_to_yaml).and_return(no_yaml)
    allow(TrainingModule).to receive(:path_to_yaml).and_return(no_yaml)
    allow(TrainingLibrary).to receive(:path_to_yaml).and_return(no_yaml)
    login_as(basque_user, scope: :user)
  end

  it 'shows the translated text of a quiz' do
     VCR.use_cassette 'training/slide_translations' do
        visit '/training/editing-wikipedia/wikipedia-essentials/five-pillars-quiz-1'
        expect(page).to have_content "Wikipedia artikulu batek"
     end
  end

  it 'shows the translated names in the table of contents' do
     VCR.use_cassette 'training/slide_translations' do
        visit '/training/editing-wikipedia/wikipedia-essentials/five-pillars-quiz-1'
        expect(page).to have_css('.slide__menu__nav__dropdown ol', :text => "Bost euskarriei buruzko proba", :visible => false)
     end
  end
end
