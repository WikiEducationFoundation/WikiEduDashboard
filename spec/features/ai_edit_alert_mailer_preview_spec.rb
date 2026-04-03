# frozen_string_literal: true

require 'rails_helper'

describe 'Mailer previews index', type: :feature, js: true do
  it 'renders the index and every linked email preview without error' do
    visit '/mailer_previews'
    expect(page).to have_content 'Email Previews'
    expect(page).to have_content 'AI edit detection'

    links = all('ul.preview-links a').map { |a| a[:href] }
    expect(links).not_to be_empty

    links.each do |url|
      visit url
      expect(page).not_to have_content 'Unknown action'
      expect(page).not_to have_content 'AbstractController::ActionNotFound'
      expect(page).not_to have_content 'NoMethodError'
      expect(page).not_to have_content 'ActionView::Template::Error'
      visit '/mailer_previews'
      expect(page).to have_content 'Email Previews'
    end
  end
end
