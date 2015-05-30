require 'rails_helper'
require "#{Rails.root}/lib/wiki_edits"

describe WikiEdits do
  # We're not testing any of the network stuff, nor whether the requests are
  # well-formatted, but at least this verifies that the flow is parsing tokens
  # in the expected way.
  describe '.notify_untrained' do
    it 'should post talk page messages on Wikipedia' do
      create(:course,
             id: 1)
      create(:user,
             id: 1,
             wiki_token: 'foo',
             wiki_secret: 'bar')
      create(:user,
             id: 2,
             wiki_token: 'foo',
             wiki_secret: 'bar')
      create(:courses_user,
             course_id: 1,
             user_id: 1)
      create(:courses_user,
             course_id: 1,
             user_id: 2)
      # rubocop:disable Metrics/LineLength
      fake_tokens = "{\"query\":{\"tokens\":{\"csrftoken\":\"myfaketoken+\\\\\"}}}"
      # rubocop:enable Metrics/LineLength
      stub_request(:get, /.*wikipedia.*/)
        .to_return(status: 200, body: fake_tokens, headers: {})
      stub_request(:post, /.*wikipedia.*/)
        .to_return(status: 200, body: 'success', headers: {})
      WikiEdits.notify_untrained(1, User.first)
    end
  end
end
