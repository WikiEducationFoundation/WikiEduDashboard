# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/watchlist_edits"

describe WatchlistEdits do
  before do
    create(:user, id: 2, username: 'user2', wiki_token: 'foo', wiki_secret: 'bar')
  end

  let(:watchlist_edits) { described_class.new }

  describe '#oauth_credentials_valid?' do
    let(:tokens) { OpenStruct.new(action_token: 'token', access_token: 'access_token') }
    let(:wiki_edits) { instance_double(WikiEdits) }
    let(:current_user) { User.find(2) }

    before do
      allow(watchlist_edits).to receive(:get_tokens).and_return(tokens)
      allow(watchlist_edits).to receive(:add_to_watchlist)
      allow(WikiEdits).to receive(:new).and_return(wiki_edits)
    end

    it 'calls get_tokens, sets watch and access tokens, and calls add_to_watchlist' do
      expect(watchlist_edits).to receive(:get_tokens).with(current_user, 'watch').and_return(tokens)
      expect(watchlist_edits).to receive(:add_to_watchlist)
      watchlist_edits.oauth_credentials_valid?(current_user)
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
