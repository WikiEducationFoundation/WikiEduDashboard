# frozen_string_literal: true

require 'rails_helper'

describe 'training library overview page', type: :feature, js: true do
  before { TrainingModule.load_all }

  it 'loads cleanly' do
    visit '/training/students'
    expect(page).to have_content('Student Training Modules')
    expect(page).to be_axe_clean
  end
end
