# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/wiki_edits"

describe WikiEdits do
  # We're not testing any of the network stuff, nor whether the requests are
  # well-formatted, but at least this verifies that the flow is parsing tokens
  # in the expected way.
  before do
    allow(Features).to receive(:disable_wiki_output?).and_return(false)
    create(:course,
           id: 1,
           submitted: true,
           slug: 'University/Course_(term)')
    create(:user,
           id: 1,
           wiki_token: 'foo',
           wiki_secret: 'bar')
    create(:user,
           id: 2,
           username: 'user2',
           wiki_token: 'foo',
           wiki_secret: 'bar')
    create(:courses_user,
           course_id: 1,
           user_id: 1)
    create(:courses_user,
           course_id: 1,
           user_id: 2)
  end

  let(:course) { Course.find(1) }

  it 'handles failed edits' do
    stub_oauth_edit_failure
    WikiEdits.new.notify_untrained(course, User.first)
  end

  it 'handles edits that hit the abuse filter' do
    stub_oauth_edit_abusefilter
    WikiEdits.new.notify_untrained(course, User.first)
  end

  it 'handles unexpected responses' do
    stub_oauth_edit_captcha
    WikiEdits.new.notify_untrained(course, User.first)
  end

  it 'handles unexpected responses' do
    stub_oauth_edit_with_empty_response
    WikiEdits.new.notify_untrained(course, User.first)
  end

  it 'handles failed token requests' do
    stub_token_request_failure
    result = WikiEdits.new.post_whole_page(User.first, 'Foo', 'Bar')
    expect(result[:status]).to eq('failed')
    expect(User.first.wiki_token).to eq('invalid')
  end

  it 'handles edit requests that are blocked' do
    stub_edit_failure_blocked
    expect(BlockedEditsReporter).to receive(:create_alerts_for_blocked_edits)
    WikiEdits.new.post_whole_page(User.first, 'Foo', 'Bar')
  end

  it 'handles edit requests that are autoblocked' do
    stub_edit_failure_autoblocked
    expect(BlockedEditsReporter).to receive(:create_alerts_for_blocked_edits)
    WikiEdits.new.post_whole_page(User.first, 'Foo', 'Bar')
  end

  describe '.notify_untrained' do
    it 'posts talk page messages on Wikipedia' do
      stub_oauth_edit
      WikiEdits.new.notify_untrained(course, User.first)
    end
  end

  describe '.notify_users' do
    it 'posts talk page messages on Wikipedia' do
      stub_oauth_edit
      params = { sectiontitle: 'My message headline',
                 text: 'My message to you',
                 summary: 'My edit summary' }
      WikiEdits.new.notify_users(User.first, User.all, params)
    end
  end

  describe '.oauth_credentials_valid?' do
    it 'returns true if credentials are valid' do
      stub_token_request
      response = WikiEdits.new.oauth_credentials_valid?(User.first)
      expect(response).to eq(true)
    end

    it 'returns false if credentials are invalid' do
      stub_token_request_failure
      response = WikiEdits.new.oauth_credentials_valid?(User.first)
      expect(response).to eq(false)
    end

    # By default, if a user is logged in, they are assumed to have valid tokens.
    # If there is a network problem, or other issue besides MediaWiki saying
    # that the auth is invalid, then we carry on.
    it 'returns true if Wikipedia API returns no tokens' do
      stub_request(:any, /.*/).to_return(status: 200, body: '{}', headers: {})
      response = WikiEdits.new.oauth_credentials_valid?(User.first)
      expect(response).to eq(true)
    end

    it 'returns true if Wikipedia API is down with 503 error' do
      stub_wikimedia_error(code: 503)
      response = WikiEdits.new.oauth_credentials_valid?(User.first)
      expect(response).to eq(true)
    end

    it 'returns true if Wikipedia is down with 500 error' do
      stub_wikimedia_error(code: 500)
      response = WikiEdits.new.oauth_credentials_valid?(User.first)
      expect(response).to eq(true)
    end
  end
end
