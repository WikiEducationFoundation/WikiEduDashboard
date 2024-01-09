# frozen_string_literal: true

require 'rails_helper'
require_dependency "#{Rails.root}/lib/lift_wing_api.rb"

describe LiftWingApi do
  context 'when the wiki is not a wikipedia or wikidata' do
    before { stub_wiki_validation }

    let!(:wiki) { create(:wiki, project: 'wikivoyage', language: 'en') }
    let(:subject0) { described_class.new(wiki) }

    it 'raises an error' do
      expect { subject0 }.to raise_error LiftWingApi::InvalidProjectError
    end
  end

  describe '#get_single_revision_parsed_data' do
    let(:rev_id) { 829840085 }
    let(:deleted_rev_id) { 708326238 }
    let(:wiki) { create(:wiki, project: 'wikidata', language: nil) }

    let(:subject0) { described_class.new(Wiki.find(1)).get_single_revision_parsed_data(rev_id) }
    let(:subject1) { described_class.new(wiki).get_single_revision_parsed_data(rev_id) }
    let(:subject2) do
      described_class.new(Wiki.find(1)).get_single_revision_parsed_data(deleted_rev_id)
    end

    it 'fetches json from api.wikimedia.org for wikipedia', vcr: true do
      expect(subject0).to be_a(Hash)
      expect(subject0.dig('wp10').to_f).to eq(29.15228958136511656)
      expect(subject0.dig('features')).to be_a(Hash)
      expect(subject0.dig('deleted')).to eq(false)
      expect(subject0.dig('prediction')).to eq('Start')
    end

    it 'fetches json from api.wikimedia.org for wikidata', vcr: true do
      expect(subject1).to be_a(Hash)
      expect(subject1.dig('wp10')).to eq(nil)
      expect(subject1.dig('features')).to be_a(Hash)
      expect(subject1.dig('deleted')).to eq(false)
      expect(subject1.dig('prediction')).to eq('D')
    end

    it 'returns deleted equal to true if the revision was deleted', vcr: true do
      expect(subject2).to be_a(Hash)
      expect(subject2.dig('wp10')).to eq(nil)
      expect(subject2.dig('features')).to eq(nil)
      expect(subject2.dig('deleted')).to eq(true)
      expect(subject2.dig('prediction')).to eq(nil)
    end

    it 'handles timeout errors' do
      stub_request(:any, 'https://api.wikimedia.org')
        .to_raise(Errno::ETIMEDOUT)
      expect_any_instance_of(described_class).to receive(:log_error).once
      expect(subject0).to be_empty
    end

    it 'handles connection refused errors' do
      stub_request(:any, 'https://api.wikimedia.org')
        .to_raise(Faraday::ConnectionFailed)
      expect_any_instance_of(described_class).to receive(:log_error).once
      expect(subject0).to be_empty
    end
  end
end
