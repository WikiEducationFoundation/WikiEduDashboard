# frozen_string_literal: true

require 'rails_helper'

describe 'mass enrollment admin page', type: :feature, js: true do
  let(:admin) { create(:admin) }
  let(:course) { create(:course) }

  before { login_as(admin) }
  after { logout }

  it 'loads cleanly' do
    visit "/mass_enrollment/#{course.slug}"
    expect(page).to have_content 'Add users to'
    expect(page).to be_axe_clean
  end
end
