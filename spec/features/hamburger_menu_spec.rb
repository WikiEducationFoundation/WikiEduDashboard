# frozen_string_literal: true

require 'rails_helper'

describe 'Hamburger navigation menu', type: :feature, js: true do
  let(:course) { create(:course) }

  it 'works when the window is narrow' do
    visit "/courses/#{course.slug}"
    expect(page).to have_content 'Help'
    page.current_window.resize_to(500, 500)
    expect(page).not_to have_content 'Help'
    expect(page).to have_css('.bm-burger-button[aria-label="Navigation menu"]')
    expect(page).to have_css('.bm-burger-button[aria-expanded="false"]')
    expect(page).to have_css('.bm-burger-button[aria-controls="hamburger-navigation-menu"]')
    expect(page).to have_css('#hamburger-navigation-menu', visible: false)

    find('.bm-burger-button').click
    expect(page).to have_css('.bm-burger-button[aria-expanded="true"]')
    expect(page).to have_content 'Explore'

    find('.bm-menu-active').click
    expect(page).to have_css('.bm-burger-button[aria-expanded="false"]')
    expect(page).not_to have_content 'Explore'
    page.current_window.resize_to(1200, 1200)
  end
end
