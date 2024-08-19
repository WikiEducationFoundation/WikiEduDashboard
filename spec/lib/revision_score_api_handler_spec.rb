# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/revision_score_api_handler"

describe RevisionScoreApiHandler do
  context 'when the wiki works for both lift wing and reference-counter APIs' do
    let(:handler) { described_class.new(wiki: Wiki.find(1)) }
    let(:subject) { handler.get_revision_data [829840090, 829840091] }

    describe '#get_revision_data' do
      it 'returns completed scores if retrieves data without errors' do
        VCR.use_cassette 'revision_score_api_handler/en_wikipedia' do
          expect(subject).to be_a(Hash)
          expect(subject.dig('829840090', 'wp10').to_f).to be_within(0.01).of(62.805729915108664)
          expect(subject.dig('829840090', 'features')).to be_a(Hash)
          # Only num_ref feature is stored. LiftWing features are discarded.
          expect(subject.dig('829840090', 'features')).to eq({ 'num_ref' => 132 })
          expect(subject.dig('829840090', 'deleted')).to eq(false)
          expect(subject.dig('829840090', 'prediction')).to eq('B')

          expect(subject.dig('829840091', 'wp10').to_f).to be_within(0.01).of(39.507631367268004)
          expect(subject.dig('829840091', 'features')).to be_a(Hash)
          # Only num_ref feature is stored. LiftWing features are discarded.
          expect(subject.dig('829840091', 'features')).to eq({ 'num_ref' => 1 })
          expect(subject.dig('829840091', 'deleted')).to eq(false)
          expect(subject.dig('829840091', 'prediction')).to eq('C')
        end
      end

      it 'returns completed scores if there is an error hitting LiftWingApi' do
        VCR.use_cassette 'revision_score_api_handler/en_wikipedia_liftwing_error' do
          stub_request(:any, /.*api.wikimedia.org.*/)
            .to_raise(Errno::ETIMEDOUT)
          expect(subject).to be_a(Hash)
          expect(subject.dig('829840090')).to eq({ 'wp10' => nil,
          'features' => { 'num_ref' => 132 }, 'deleted' => false, 'prediction' => nil })
          expect(subject.dig('829840091')).to eq({ 'wp10' => nil,
          'features' => { 'num_ref' => 1 }, 'deleted' => false, 'prediction' => nil })
        end
      end

      it 'returns completed scores if there is an error hitting ReferenceCounterApi' do
        VCR.use_cassette 'revision_score_api_handler/en_wikipedia_reference_counter_error' do
          stub_request(:any, /.*reference-counter.toolforge.org*/)
            .to_raise(Errno::ETIMEDOUT)

          expect(subject).to be_a(Hash)

          expect(subject.dig('829840090', 'wp10').to_f).to be_within(0.01).of(62.805729915108664)
          expect(subject.dig('829840090')).to have_key('features')
          expect(subject.dig('829840090', 'features')).to be_nil
          expect(subject.dig('829840090', 'deleted')).to eq(false)
          expect(subject.dig('829840090', 'prediction')).to eq('B')

          expect(subject.dig('829840091', 'wp10').to_f).to be_within(0.01).of(39.507631367268004)
          expect(subject.dig('829840091')).to have_key('features')
          expect(subject.dig('829840091', 'features')).to be_nil
          expect(subject.dig('829840091', 'deleted')).to eq(false)
          expect(subject.dig('829840091', 'prediction')).to eq('C')
        end
      end
    end

    it 'returns completed scores if there is an error hitting both apis' do
      stub_request(:any, /.*api.wikimedia.org.*/)
        .to_raise(Errno::ETIMEDOUT)
      stub_request(:any, /.*reference-counter.toolforge.org*/)
        .to_raise(Errno::ETIMEDOUT)
      expect(subject).to be_a(Hash)
      expect(subject.dig('829840090')).to eq({ 'wp10' => nil,
      'features' => nil, 'deleted' => false, 'prediction' => nil })
      expect(subject.dig('829840091')).to eq({ 'wp10' => nil,
      'features' => nil, 'deleted' => false, 'prediction' => nil })
    end
  end

  context 'when the wiki is available only for LiftWing API' do
    before { stub_wiki_validation }

    let(:wiki) { create(:wiki, project: 'wikidata', language: nil) }
    let(:handler) { described_class.new(wiki:) }
    let(:subject) { handler.get_revision_data [144495297, 144495298] }

    describe '#get_revision_data' do
      it 'returns completed scores if retrieves data without errors' do
        VCR.use_cassette 'revision_score_api_handler/wikidata' do
          expect(subject).to be_a(Hash)
          expect(subject.dig('144495297', 'wp10').to_f).to eq(0)
          expect(subject.dig('144495297', 'features')).to be_a(Hash)
          expect(subject.dig('144495297', 'features',
                             'feature.len(<datasource.wikidatawiki.revision.references>)')).to eq(2)
          # 'num_ref' key doesn't exist for wikidata features
          expect(subject.dig('144495297', 'features').key?('num_ref')).to eq(false)
          expect(subject.dig('144495297', 'deleted')).to eq(false)
          expect(subject.dig('144495297', 'prediction')).to eq('D')

          expect(subject.dig('144495298', 'wp10').to_f).to eq(0)
          expect(subject.dig('144495298', 'features')).to be_a(Hash)
          expect(subject.dig('144495298', 'features',
                             'feature.len(<datasource.wikidatawiki.revision.references>)')).to eq(0)
          # 'num_ref' key doesn't exist for wikidata features
          expect(subject.dig('144495298', 'features').key?('num_ref')).to eq(false)
          expect(subject.dig('144495298', 'deleted')).to eq(false)
          expect(subject.dig('144495298', 'prediction')).to eq('E')
        end
      end

      it 'returns completed scores if there is an error hitting LiftWingApi' do
        stub_request(:any, /.*api.wikimedia.org.*/)
          .to_raise(Errno::ETIMEDOUT)
        expect(subject).to be_a(Hash)
        expect(subject.dig('144495297')).to eq({ 'wp10' => nil,
        'features' => nil, 'deleted' => false, 'prediction' => nil })
        expect(subject.dig('144495298')).to eq({ 'wp10' => nil,
        'features' => nil, 'deleted' => false, 'prediction' => nil })
      end
    end
  end

  context 'when the wiki is available only for reference-counter API' do
    before { stub_wiki_validation }

    let(:wiki) { create(:wiki, project: 'wikipedia', language: 'es') }
    let(:handler) { described_class.new(wiki:) }
    let(:subject) { handler.get_revision_data [157412237, 157417768] }

    describe '#get_revision_data' do
      it 'returns completed scores if retrieves data without errors' do
        VCR.use_cassette 'revision_score_api_handler/es_wikipedia' do
          expect(subject).to be_a(Hash)
          expect(subject.dig('157412237')).to eq({ 'wp10' => nil,
          'features' => { 'num_ref' => 111 }, 'deleted' => false, 'prediction' => nil })
          expect(subject.dig('157417768')).to eq({ 'wp10' => nil,
          'features' => { 'num_ref' => 42 }, 'deleted' => false, 'prediction' => nil })
        end
      end

      it 'returns completed scores if there is an error hitting reference-counter api' do
        stub_request(:any, /.*reference-counter.toolforge.org*/)
          .to_raise(Errno::ETIMEDOUT)
        expect(subject).to be_a(Hash)
        expect(subject.dig('157412237')).to eq({ 'wp10' => nil,
        'features' => nil, 'deleted' => false, 'prediction' => nil })
        expect(subject.dig('157417768')).to eq({ 'wp10' => nil,
        'features' => nil, 'deleted' => false, 'prediction' => nil })
      end
    end
  end
end
