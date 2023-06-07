# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/watchlist_edits"

describe WatchlistEdits do
  before do
    create(:user, id: 2, username: 'user2', wiki_token: 'foo', wiki_secret: 'bar')
  end

  let(:watchlist_edits) { described_class.new(nil, User.find(2)) }

  describe '#retrieve_tokens' do
    let(:tokens) { OpenStruct.new(watch_token: 'token', access_token: 'access_token') }
    let(:wiki_edits) { instance_double(WikiEdits) }

    before do
      allow(watchlist_edits).to receive(:get_tokens).and_return(tokens)
      allow(WikiEdits).to receive(:new).and_return(wiki_edits)
    end

    it 'calls get_tokens and sets watch and access tokens' do
      expect(watchlist_edits).to receive(:get_tokens).with(User.find(2), 'watch').and_return(tokens)
      watchlist_edits.retrieve_tokens
    end
  end

  describe '#watch_userpages' do
    let(:access_token) { instance_double('OAuth::AccessToken') }
    let(:api_url) { 'https://en.wikipedia.org/w/api.php' }
    let(:data) do
      {
        action: 'watch',
        format: 'json',
        titles: 'user1',
        token: 'watch_token',
        formatversion: '2'
      }
    end

    before do
      watchlist_edits.instance_variable_set(:@watch_token, 'watch_token')
      watchlist_edits.instance_variable_set(:@access_token, access_token)
      allow(access_token).to receive(:post)
    end

    context 'when users is empty' do
      it 'returns { status: "no users" }' do
        response = watchlist_edits.watch_userpages([])
        expect(response).to eq({ status: 'no users' })
      end
    end

    context 'when retrieve_tokens returns false' do
      before do
        allow(watchlist_edits).to receive(:retrieve_tokens).and_return(false)
      end

      it 'returns { status: "token retrieval failed" }' do
        response = watchlist_edits.watch_userpages(['user1'])
        expect(response).to eq({ status: 'token retrieval failed' })
      end
    end

    context 'when users is not empty and retrieve_tokens returns true' do
      before do
        allow(watchlist_edits).to receive(:retrieve_tokens).and_return(true)
      end

      it 'calls post method on access_token with the correct data' do
        expect(access_token).to receive(:post).with(api_url, data)
        watchlist_edits.watch_userpages(['user1'])
      end
    end
  end
end
