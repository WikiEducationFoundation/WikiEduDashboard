# frozen_string_literal: true

require 'rails_helper'

describe 'copy course page', type: :feature, js: true do
  let(:admin) { create(:admin) }

  before { login_as(admin) }
  after { logout }

  it 'loads cleanly' do
    visit '/copy_course'
    expect(page).to have_content 'Copy course from another server'
    expect(page).to be_axe_clean
  end
end
