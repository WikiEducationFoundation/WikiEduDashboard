# frozen_string_literal: true

require 'rails_helper'

describe FindOriginRevisions do
  let(:wiki) { Wiki.default_wiki }
  let(:passages) { ['Two hills lie east of the city.'] }
  let(:wikiwho) { instance_double(WikiWhoApi) }
  let(:wiki_api) { instance_double(WikiApi) }
  let(:revisions_info) do
    [{ 'revid' => 5, 'user' => 'Older', 'timestamp' => '2023-01-02T00:00:00Z' },
     { 'revid' => 7, 'user' => 'Newer', 'timestamp' => '2024-01-02T00:00:00Z' }]
  end
  let(:history) { { 'pages' => { '1' => { 'revisions' => [{ 'revid' => 10 }] } } } }

  def api_response(data)
    instance_double(MediawikiApi::Response, data:).tap do |response|
      allow(response).to receive(:[]).with('continue').and_return(nil)
    end
  end

  before do
    allow(WikiWhoApi).to receive(:new).and_return(wikiwho)
    allow(WikiApi).to receive(:new).and_return(wiki_api)
    allow(wiki_api).to receive(:query).with(hash_including(revids: '7|5'))
      .and_return(api_response('pages' => { '1' => { 'revisions' => revisions_info } }))
    allow(wiki_api).to receive(:query).with(hash_including(pageids: 1, rvstartid: 10))
      .and_return(api_response(history))
  end

  def origins(article)
    described_class.new(wiki:, article:, rev_id: 10, passages:).origins
  end

  context 'with a mainspace article' do
    let(:article) { build(:article, namespace: Article::Namespaces::MAINSPACE, mw_page_id: 1) }

    it 'uses WikiWho, listing the origin with the most words first' do
      allow(wikiwho).to receive(:rev_content).with(10).and_return([])
      allow(WikiWhoPassageAttributor).to receive(:new)
        .and_return(instance_double(WikiWhoPassageAttributor, word_counts: { 7 => 6, 5 => 1 }))
      expect(origins(article)).to eq(
        [{ rev_id: 7, username: 'Newer', timestamp: Time.zone.parse('2024-01-02'), words: 6 },
         { rev_id: 5, username: 'Older', timestamp: Time.zone.parse('2023-01-02'), words: 1 }]
      )
    end

    it 'falls back to the page history when WikiWho cannot answer' do
      allow(wikiwho).to receive(:rev_content).and_return(nil)
      expect(HistoryPassageAttributor).to receive(:new)
        .with(passages:, revisions: [{ 'revid' => 10 }], complete: true, wiki:)
        .and_return(instance_double(HistoryPassageAttributor, word_counts: { 7 => 6, 5 => 1 }))
      expect(origins(article).map { |origin| origin[:rev_id] }).to eq([7, 5])
    end
  end

  context 'with a sandbox' do
    let(:article) { build(:article, namespace: Article::Namespaces::USER, mw_page_id: 1) }

    it 'searches the page history without asking WikiWho' do
      expect(wikiwho).not_to receive(:rev_content)
      allow(HistoryPassageAttributor).to receive(:new)
        .and_return(instance_double(HistoryPassageAttributor, word_counts: { 7 => 6, 5 => 1 }))
      expect(origins(article).map { |origin| origin[:rev_id] }).to eq([7, 5])
    end
  end
end
