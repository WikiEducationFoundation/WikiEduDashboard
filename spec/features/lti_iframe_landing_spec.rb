# frozen_string_literal: true

require 'rails_helper'

describe 'LTI iframe landing page', type: :feature, js: true do
  before do
    allow(Features).to receive_messages(canvas_integration?: true, wiki_ed?: true)
  end

  it 'renders the minimal stance-neutral landing with a single top-level break-out button' do
    visit '/lti?ltik=ltik-abc'

    # Page title that names the destination — stance-neutral on signed-in state.
    expect(page).to have_content('Wiki Education Dashboard')

    # The single visible call to action.
    button = find_link('Open the Wiki Education Dashboard')
    expect(button[:href]).to end_with('/lti/connect_course?ltik=ltik-abc')
    expect(button[:target]).to eq('_blank')

    # Dashboard navbar must NOT render — inside Canvas's iframe it would
    # always show "logged out" (cookies are partitioned) and mislead any
    # user who is signed in to the dashboard in their main browser.
    expect(page).to have_no_css('#nav_root', visible: :all)
  end
end
