# frozen_string_literal: true

require 'rails_helper'

# The blocked request below logs a JSONP failure to the browser console, which
# is what this spec is about rather than a fault in it.
describe 'article finder when a request fails', type: :feature, js: true,
         js_error_expected: true do
  let(:course) { create(:course) }
  let(:admin) { create(:admin) }

  before do
    login_as(admin)
    stub_wiki_validation
    stub_oauth_edit
  end

  # Stops the browser reaching the page views API, which is the last round of
  # requests a search makes. The search itself still succeeds, so this isolates
  # a failure part-way through a search.
  def block_pageviews
    page.driver.browser.execute_cdp('Network.enable')
    page.driver.browser.execute_cdp('Network.setBlockedURLs', urls: ['*prop=pageviews*'])
  end

  it 'ends the search so another one can be run' do
    visit "/courses/#{course.slug}/article_finder"
    block_pageviews

    within '.article-finder-form' do
      fill_in 'article-searchbar', with: 'Selfie'
      click_button 'Search'
    end

    expect(page).to have_content 'Monkey selfie copyright dispute'
    # Waiting for the error is also what tells us the failure has been handled,
    # so the state of the page below is its final state. Page views are
    # requested five articles at a time, so the one notification is also the
    # whole round of requests reporting itself once.
    expect(page).to have_css('.notifications .notice', count: 1, wait: 10)

    # The search is over, whether or not every request returned data, so its
    # progress indicator stops and the search button becomes usable again.
    expect(page).to have_no_css('.loading__spinner__small')
    expect(page).to have_button('Search', disabled: false)
  end
end
