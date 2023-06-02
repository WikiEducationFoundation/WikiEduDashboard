# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/watchlist_edits"

describe WatchlistEdits do
  before do
    create(:user, id: 1, wiki_token: 'foo', wiki_secret: 'bar')
    create(:user, id: 2, username: 'user2', wiki_token: 'foo', wiki_secret: 'bar')
  end

  let(:current_user) { User.find(1) }
  let(:watchlist_edits) { described_class.new }

  describe '#oauth_credentials_valid?' do
    context 'when current_user is nil' do
      it 'returns "no current user"' do
        response = watchlist_edits.oauth_credentials_valid?(nil)
        expect(response).to eq({ status: 'no current user' })
      end
    end

    context 'when current_user is present' do
      before do
        access_token_double = instance_double('OAuth::AccessToken')
        allow(access_token_double).to receive(:get).and_return(
          instance_double('Net::HTTPResponse',
                          code: '200', body: '{"query":{"tokens":{"watchtoken":"abc123"}}}')
        )
        allow(watchlist_edits).to receive(:oauth_access_token).and_return(access_token_double)
        stub_token_request
      end

      it 'calls fetch_watch_token' do
        expect(watchlist_edits).to receive(:fetch_watch_token).with(current_user)
        watchlist_edits.oauth_credentials_valid?(current_user)
      end

      it 'calls add_to_watchlist' do
        expect(watchlist_edits).to receive(:add_to_watchlist)
        watchlist_edits.oauth_credentials_valid?(current_user)
      end
    end
  end

  describe '#add_to_watchlist' do
    context 'when watch_token is nil' do
      before do
        watchlist_edits.instance_variable_set(:@watch_token, nil)
      end

      it 'returns { status: "no watch token" }' do
        response = watchlist_edits.send(:add_to_watchlist)
        expect(response).to eq({ status: 'no watch token' })
      end

      context 'when watch_token is present' do
        let(:access_token) { instance_double('OAuth::AccessToken') }
        let(:api_url) { 'https://en.wikipedia.org/w/api.php' }
        let(:data) do
          {
            action: 'watch',
            format: 'json',
            titles: '',
            token: 'watch_token',
            formatversion: '2'
          }
        end

        before do
          watchlist_edits.instance_variable_set(:@watch_token, 'watch_token')
          watchlist_edits.instance_variable_set(:@access_token, access_token)
          allow(access_token).to receive(:post)
        end

        it 'calls post method on access_token' do
          expect(access_token).to receive(:post).with(api_url, data)
          watchlist_edits.send(:add_to_watchlist)
        end
      end
    end
  end
end
