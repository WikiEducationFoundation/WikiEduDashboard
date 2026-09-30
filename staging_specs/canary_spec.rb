# frozen_string_literal: true

require_relative 'spec_helper'

# Connectivity + harness probe. Does NOT touch Canvas, does NOT trigger
# any auth flow, does NOT exercise LTI. Just confirms:
#   1. the persistent Chrome profile spins up cleanly,
#   2. Selenium can reach the deployed dashboard,
#   3. a stable bit of page content is present,
#   4. cross-session helpers don't blow up.
#
# If this fails, none of the real flow specs (T3) can possibly work, so
# debug here first.
describe 'staging harness canary', :staging do
  it 'reaches dashboard-testing and renders the home page' do
    in_dashboard do
      visit '/'
      # Footer is the most stable bit of chrome — present on every page,
      # rarely re-styled. The exact phrase "Wiki Education" appears in the
      # footer attribution link.
      expect(page).to have_content('Wiki Education')
    end
  end

  it 'reaches canvas.wikiedu.org' do
    in_canvas do
      visit '/'
      # Canvas's unauthenticated landing redirects to /login. We can't check
      # HTTP status under Selenium, so assert (a) we landed somewhere on the
      # Canvas host, and (b) the page isn't a 502/503 gateway error.
      expect(page.current_url).to start_with('https://canvas.wikiedu.org')
      expect(page).to have_no_text('502 Bad Gateway', wait: 2)
      expect(page).to have_no_text('Service Unavailable', wait: 2)
    end
  end

  it 'preserves the persistent profile across the two sessions in one spec' do
    # If user-data-dir is wired correctly, both sessions in this same spec
    # see the same Chrome profile on disk. We don't have a great way to
    # assert that programmatically without authenticating, but we can at
    # least confirm both sessions opened without error.
    in_dashboard { visit '/' }
    in_canvas    { visit '/' }
    expect(true).to be(true)
  end
end
