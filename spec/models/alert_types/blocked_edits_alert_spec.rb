# frozen_string_literal: true

require 'rails_helper'

describe BlockedEditsAlert do
  let(:user) { create(:user, username: 'Ragesock') }

  let(:local_block_details) do
    { 'error' => { 'code' => 'blocked',
                   'info' => 'You have been blocked from editing.',
                   'blockinfo' => { 'blockid' => 17605815,
                                    'blockedby' => 'Orange Mike' } },
      'wiki_domain' => 'es.wikipedia.org' }
  end

  # Global blocks arrive with the generic 'blocked' code; the giveaway is the
  # 'Global blocks' link in the info text.
  let(:global_block_details) do
    { 'error' => { 'code' => 'blocked',
                   'info' => "'''Your IP address is in a range that has been " \
                             '[[m:Special:MyLanguage/Global blocks|blocked on all ' \
                             "Wikimedia Foundation wikis]].''' " \
                             'The block was made by [[User:M7|M7]].',
                   'blockinfo' => { 'blockid' => 3455747,
                                    'blockedby' => 'M7' } },
      'wiki_domain' => 'en.wikipedia.org' }
  end

  context 'for a local block' do
    it 'links to the block list of the wiki where the edit was blocked' do
      alert = described_class.new(user:, details: local_block_details)
      expect(alert.ticket_body)
        .to include('https://es.wikipedia.org/wiki/Special:BlockList?wpTarget=%2317605815')
    end

    it 'links to the blocking user talk page on the wiki where the edit was blocked' do
      alert = described_class.new(user:, details: local_block_details)
      expect(alert.ticket_body).to include('https://es.wikipedia.org/wiki/User_talk:Orange_Mike')
    end

    it 'falls back to English Wikipedia when no wiki domain is recorded' do
      alert = described_class.new(user:, details: local_block_details.except('wiki_domain'))
      expect(alert.ticket_body)
        .to include('https://en.wikipedia.org/wiki/Special:BlockList?wpTarget=%2317605815')
    end
  end

  context 'for a global block' do
    it 'links to the global block list on Meta' do
      alert = described_class.new(user:, details: global_block_details)
      expect(alert.ticket_body)
        .to include('https://meta.wikimedia.org/wiki/Special:GlobalBlockList?target=%233455747')
    end

    it 'links to the blocking user talk page on Meta' do
      alert = described_class.new(user:, details: global_block_details)
      expect(alert.ticket_body).to include('https://meta.wikimedia.org/wiki/User_talk:M7')
    end

    it 'detects global blocks from globalblocking error codes' do
      details = global_block_details
      details['error']['code'] = 'wikimedia-globalblocking-ipblocked-range'
      details['error']['info'] = 'localized message without the usual link'
      alert = described_class.new(user:, details:)
      expect(alert.ticket_body).to include('Special:GlobalBlockList?target=%233455747')
    end
  end
end
