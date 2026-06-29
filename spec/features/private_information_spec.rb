# frozen_string_literal: true

require 'rails_helper'

describe 'private information page', type: :feature, js: true do
  it 'loads cleanly' do
    visit '/private_information'
    expect(page).to have_content 'Private Information'
    expect(page).to be_axe_clean
  end
end
