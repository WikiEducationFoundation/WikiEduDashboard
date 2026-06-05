# frozen_string_literal: true

require 'rails_helper'

# Direct axe-clean checks against the error views via their /errors/ routes.
# Avoids the "show real errors" Rails.env config dance in error_pages_spec.rb
# (which uses the non-JS driver) — axe-core-rspec needs JS.
describe 'error pages', type: :feature, js: true do
  it 'incorrect_passcode loads cleanly' do
    visit '/errors/incorrect_passcode'
    expect(page).to have_content 'Incorrect passcode'
    expect(page).to be_axe_clean
  end

  it 'file_not_found loads cleanly' do
    visit '/errors/file_not_found'
    expect(page).to have_content 'Page not found'
    expect(page).to be_axe_clean
  end

  it 'unprocessable loads cleanly' do
    visit '/errors/unprocessable'
    expect(page).to have_content 'unprocessable'
    expect(page).to be_axe_clean
  end

  it 'internal_server_error loads cleanly' do
    visit '/errors/internal_server_error'
    expect(page).to have_content 'internal server error'
    expect(page).to be_axe_clean
  end

  it 'login_error loads cleanly' do
    visit '/errors/login_error'
    expect(page).to have_content 'Login Error'
    expect(page).to be_axe_clean
  end
end
