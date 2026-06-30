# frozen_string_literal: true

require 'rails_helper'

describe 'accessibility (VPAT) page', type: :feature, js: true do
  it 'loads cleanly and renders the conformance report' do
    visit '/accessibility'
    expect(page).to have_content 'WCAG 2.1 Report'
    expect(page).to have_selector 'table'
    expect(page).to be_axe_clean
  end
end
