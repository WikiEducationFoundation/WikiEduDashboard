# frozen_string_literal: true

require 'rails_helper'
require_dependency "#{Rails.root}/lib/lift_wing_api.rb"

describe LiftWingApi do
  context 'when the wiki is not a supported wikipedia' do
    before { stub_wiki_validation }

    it 'raises an error for non-wikipedia wikis' do
      wiki = create(:wiki, project: 'wikivoyage', language: 'en')
      expect { described_class.new(wiki) }.to raise_error LiftWingApi::InvalidProjectError
    end

    it 'raises an error for wikidata' do
      wiki = create(:wiki, project: 'wikidata', language: nil)
      expect { described_class.new(wiki) }.to raise_error LiftWingApi::InvalidProjectError
    end
  end

  describe '#get_revision_data' do
    before { stub_wiki_validation }

    let(:rev_ids) { [829840084, 829840085] }
    let(:deleted_rev_id) { 708326238 }

    let(:lift_wing_api_class_en_wiki) { described_class.new(Wiki.find(1)) }

    it 'fetches json from api.wikimedia.org for wikipedia' do
      VCR.use_cassette 'liftwing_api/wikipedia' do
        # Get revision data for valid rev ids for English Wikipedia
        subject = lift_wing_api_class_en_wiki.get_revision_data(rev_ids)
        expect(subject).to be_a(Hash)
        expect(subject.dig('829840084', 'wp10').to_f).to be_within(0.01).of(28.59)
        expect(subject.dig('829840084', 'features')).to be_a(Hash)
        expect(subject.dig('829840084', 'deleted')).to eq(false)
        expect(subject.dig('829840084', 'prediction')).to eq('Stub')
        expect(subject.dig('829840084').key?('error')).to eq(false)

        expect(subject).to be_a(Hash)
        expect(subject.dig('829840085', 'wp10').to_f).to be_within(0.01).of(29.15)
        expect(subject.dig('829840085', 'features')).to be_a(Hash)
        expect(subject.dig('829840085', 'deleted')).to eq(false)
        expect(subject.dig('829840085', 'prediction')).to eq('Start')
        expect(subject.dig('829840085').key?('error')).to eq(false)
      end
    end

    it 'returns deleted equal to true if the revision was deleted' do
      VCR.use_cassette 'liftwing_api/deleted_revision' do
        # Get revision data for deleted rev ids for English Wikipedia
        subject = lift_wing_api_class_en_wiki.get_revision_data([deleted_rev_id])
        expect(subject).to be_a(Hash)
        expect(subject.dig('708326238', 'deleted')).to eq(true)
        expect(subject.dig('708326238').key?('error')).to eq(false)
      end
    end

    context 'if the same error happens several times' do
      let(:subject) { lift_wing_api_class_en_wiki.get_revision_data(rev_ids) }

      it 'logs timeout error once' do
        stub_request(:any, /.*api.wikimedia.org.*/)
          .to_raise(Errno::ETIMEDOUT)
        expect(lift_wing_api_class_en_wiki).to receive(:log_error).once
        expect(subject.dig('829840085', 'error')).not_to be(nil)
      end

      it 'logs connection refused once' do
        stub_request(:any, /.*api.wikimedia.org.*/)
          .to_raise(Faraday::ConnectionFailed)
        expect(lift_wing_api_class_en_wiki).to receive(:log_error).once
        expect(subject.dig('829840085', 'error')).not_to be(nil)
      end

      it 'logs unexpected error once' do
        VCR.use_cassette 'liftwing_api/logs_unexpected_error' do
          allow(lift_wing_api_class_en_wiki)
            .to receive(:build_successful_response)
            .and_raise(StandardError)
          expect(lift_wing_api_class_en_wiki).to receive(:log_error).once
          expect(subject.dig('829840085', 'error')).not_to be(nil)
        end
      end
    end
  end

  # Without these, a silent Lift Wing server blocks the worker indefinitely.
  describe 'lift_wing_server connection' do
    before { stub_wiki_validation }

    let(:en_wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
    let(:conn) { described_class.new(en_wiki).send(:lift_wing_server) }

    it 'has a finite request timeout' do
      expect(conn.options.timeout).to eq(described_class::REQUEST_TIMEOUT)
      expect(conn.options.timeout).to be > 0
    end

    it 'has a finite open_timeout' do
      expect(conn.options.open_timeout).to eq(described_class::OPEN_TIMEOUT)
      expect(conn.options.open_timeout).to be > 0
    end
  end
end
