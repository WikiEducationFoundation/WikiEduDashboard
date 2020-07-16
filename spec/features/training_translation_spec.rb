# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/data_cycle/training_update"

describe 'Training Translations', type: :feature, js: true do
  let(:basque_user) { create(:user, id: 2, username: 'ibarra', locale: 'eu') }

  before do
    TrainingModule.destroy_all
    TrainingSlide.destroy_all
    TrainingLibrary.destroy_all
    allow(Features).to receive(:wiki_trainings?).and_return(true)
    VCR.use_cassette 'training/slide_translations' do
      TrainingUpdate.new(module_slug: 'all')
    end
    login_as(basque_user, scope: :user)
  end

  it 'shows the translated text of a quiz' do
    visit '/training/editing-wikipedia/wikipedia-essentials/five-pillars-quiz-1'
    expect(page).to have_content 'Wikipedia artikulu batek'
  end

  it 'shows the translated names in the table of contents' do
    visit '/training/editing-wikipedia/wikipedia-essentials/five-pillars-quiz-1'
    expect(page).to have_css('.slide__menu__nav__dropdown ol',
                             text: 'Bost euskarriei buruzko proba',
                             visible: :hidden)
  end

  # Make sure default trainings get reloaded
end
