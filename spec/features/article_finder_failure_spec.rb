# frozen_string_literal: true

require 'rails_helper'

# The blocked requests below log failures to the browser console, which is
# what these specs are about rather than a fault in them.
describe 'article finder when a request fails', type: :feature, js: true,
         js_error_expected: true do
  let(:course) { create(:course) }
  let(:admin) { create(:admin) }

  before do
    login_as(admin)
    stub_wiki_validation
    stub_oauth_edit
  end

  # The browser is shared between examples, and the block list set below
  # would otherwise outlive the example that set it.
  after do
    page.driver.browser.execute_cdp('Network.setBlockedURLs', urls: [])
  end

  # Stops the browser reaching the matching requests. They go straight from
  # the browser to Wikipedia, so this is the only place they can be blocked.
  def block_requests(pattern)
    page.driver.browser.execute_cdp('Network.enable')
    page.driver.browser.execute_cdp('Network.setBlockedURLs', urls: [pattern])
  end

  def search_for(term)
    within '.article-finder-form' do
      fill_in 'article-searchbar', with: term
      click_button 'Search'
    end
  end

  context 'part-way through a search' do
    it 'ends the search so another one can be run' do
      visit "/courses/#{course.slug}/article_finder"
      # Page views are the last round of requests a search makes; the search
      # itself still succeeds.
      block_requests('*prop=pageviews*')

      search_for 'Selfie'

      expect(page).to have_content 'Monkey selfie copyright dispute'
      # Waiting for the error is also what tells us the failure has been
      # handled, so the state of the page below is its final state. Page views
      # are requested five articles at a time, so the one notification is also
      # the whole round reporting itself once.
      expect(page).to have_css('.notifications .notice', count: 1, wait: 10)

      # The search is over, whether or not every request returned data, so its
      # progress indicator stops and the search button becomes usable again.
      expect(page).to have_no_css('.loading__spinner__small')
      expect(page).to have_button('Search', disabled: false)
    end
  end

  context 'on the very first query' do
    before { block_requests('*list=search*') }

    it 'shows the failure rather than an empty result, on the course page' do
      visit "/courses/#{course.slug}/article_finder"

      search_for 'Selfie'

      expect(page).to have_css('.notifications .notice', count: 1, wait: 10)
      expect(page).to have_no_css('#articles-fetched')
      expect(page).to have_no_css('table.category-articles')
      expect(page).to have_button('Search', disabled: false)
    end

    it 'shows the failure rather than an empty result, on the standalone page' do
      visit '/article_finder'

      search_for 'Selfie'

      # The standalone page has no course around it to render notifications,
      # so it renders its own.
      expect(page).to have_css('.notifications .notice', count: 1, wait: 10)
      expect(page).to have_no_css('#articles-fetched')
      expect(page).to have_no_css('table.category-articles')
      expect(page).to have_button('Search', disabled: false)
    end
  end

  context 'when asking for more results' do
    it 'keeps the results already on the page' do
      visit "/courses/#{course.slug}/article_finder"
      search_for 'Selfie'
      expect(page).to have_content 'Monkey selfie copyright dispute'
      expect(page).to have_button('More Results')

      # Only the second page of search results is blocked.
      block_requests('*sroffset=50*')
      click_button 'More Results', match: :first

      expect(page).to have_css('.notifications .notice', count: 1, wait: 10)
      expect(page).to have_content 'Monkey selfie copyright dispute'
      expect(page).to have_css('#articles-fetched')
      expect(page).to have_no_css('.loading__spinner__small')
      expect(page).to have_button('Search', disabled: false)
    end
  end
end
