# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/revision_score_api_handler"

describe RevisionScoreApiHandler do
  context 'when the wiki is en.wikipedia (uses reference-counter only)' do
    # LiftWing is no longer called during updates. wp10 / prediction are always nil;
    # features comes solely from ReferenceCounterApi (num_ref).
    before do
      stub_en_wikipedia_reference_counter_reponse
    end

    let(:handler) { described_class.new(wiki: Wiki.find(1)) }

    describe '#get_revision_data' do
      let(:subject) { handler.get_revision_data [829840090, 829840091] }

      it 'returns completed scores if data is retrieved without errors' do
        expect(subject).to be_a(Hash)
        expect(subject.dig('829840090')).to eq({ 'wp10' => nil, 'error' => false,
        'features' => { 'num_ref' => 132 }, 'deleted' => false, 'prediction' => nil })
        expect(subject.dig('829840091')).to eq({ 'wp10' => nil, 'error' => false,
        'features' => { 'num_ref' => 1 }, 'deleted' => false, 'prediction' => nil })
      end

      it 'returns completed scores if there is an error hitting ReferenceCounterApi' do
        stub_request(:any, /.*reference-counter.toolforge.org*/)
          .to_raise(Errno::ETIMEDOUT)

        expect(subject).to be_a(Hash)
        expect(subject.dig('829840090')).to eq({ 'wp10' => nil, 'error' => true,
        'features' => {}, 'deleted' => false, 'prediction' => nil })
        expect(subject.dig('829840091')).to eq({ 'wp10' => nil, 'error' => true,
        'features' => {}, 'deleted' => false, 'prediction' => nil })
      end
    end
  end

  context 'when the wiki is wikidata' do
    before { stub_wiki_validation }

    let(:wiki) { create(:wiki, project: 'wikidata', language: nil) }
    let(:handler) { described_class.new(wiki:) }

    # Wikidata is no longer scored via either API: Lift Wing features/wp10 aren't used for
    # Wikidata, and reference-counter doesn't support Wikidata. Deletion detection has
    # moved to UpdateWikidataStatsTimeslice (via WikidataDiffAnalyzer).
    describe '#get_revision_data' do
      it 'returns no scores and makes no HTTP calls' do
        stub_request(:any, /.*api.wikimedia.org.*/).to_raise('should not be called')
        stub_request(:any, /.*reference-counter.toolforge.org.*/).to_raise('should not be called')
        expect(handler.get_revision_data([144495297, 144495298])).to eq({})
      end
    end
  end

  context 'when the wiki is available only for reference-counter API' do
    before do
      stub_wiki_validation
      stub_es_wikipedia_reference_counter_reponse
    end

    let(:wiki) { create(:wiki, project: 'wikipedia', language: 'es') }
    let(:handler) { described_class.new(wiki:) }
    let(:subject) { handler.get_revision_data [157412237, 157417768] }

    describe '#get_revision_data' do
      it 'returns completed scores if retrieves data without errors' do
        expect(subject).to be_a(Hash)
        expect(subject.dig('157412237')).to eq({ 'wp10' => nil, 'error' => false,
        'features' => { 'num_ref' => 111 }, 'deleted' => false, 'prediction' => nil })
        expect(subject.dig('157417768')).to eq({ 'wp10' => nil, 'error' => false,
        'features' => { 'num_ref' => 42 }, 'deleted' => false, 'prediction' => nil })
      end

      it 'returns completed scores if there is an error hitting reference-counter api' do
        stub_request(:any, /.*reference-counter.toolforge.org*/)
          .to_raise(Errno::ETIMEDOUT)
        expect(subject).to be_a(Hash)
        expect(subject.dig('157412237')).to eq({ 'wp10' => nil, 'error' => true,
        'features' => {}, 'deleted' => false, 'prediction' => nil })
        expect(subject.dig('157417768')).to eq({ 'wp10' => nil, 'error' => true,
        'features' => {}, 'deleted' => false, 'prediction' => nil })
      end
    end
  end
end
