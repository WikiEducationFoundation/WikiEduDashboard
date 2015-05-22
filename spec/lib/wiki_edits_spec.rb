require 'rails_helper'
require "#{Rails.root}/lib/wiki_edits"

describe WikiEdits do
  describe '.notify_untrained' do
    pending 'should post messages to Wikipedia talk pages'
  end

  describe '.tokens' do
    it 'should get edit tokens using OAuth credentials' do
      user = create(:user,
                    wiki_token: 'foo',
                    wiki_secret: 'bar')

      fake_tokens = "{\"query\":{\"tokens\":{\"csrftoken\":\"myfaketoken+\\\\\"}}}"
      stub_request(:get, /.*/).to_return(:status => 200, :body => fake_tokens, :headers => {})
      response = WikiEdits.tokens(user)
    end
  end

  describe '.api_get' do
    pending 'should send data and tokens to Wikipedia'
  end
end
