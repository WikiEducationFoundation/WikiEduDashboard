# frozen_string_literal: true

require 'rails_helper'

describe 'training library overview page', type: :feature, js: true do
  before { TrainingModule.load_all }

  it 'loads cleanly' do
    visit '/training/students'
    expect(page).to have_content('Student Training Modules')
    expect(page).to be_axe_clean
  end

  it 'does not list slide-less in-app exercise modules' do
    visit '/training/students'
    expect(page).to have_content('Exercise: Evaluate Wikipedia')
    expect(page).not_to have_content('Exercise: Fact verification')
  end

  it 'does not list slide-less in-app exercise modules on the training index' do
    visit '/training'
    expect(page).to have_content('Exercise: Evaluate Wikipedia')
    expect(page).not_to have_content('Exercise: Fact verification')
  end
end
