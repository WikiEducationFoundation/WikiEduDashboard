# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/ores_api"

describe OresApi do
  context 'when the wiki is not a wikipedia' do
    before { stub_wiki_validation }

    let!(:wiki) { create(:wiki, project: 'wikivoyage', language: 'en') }
    let(:subject) { described_class.new(wiki) }

    it 'raises an error' do
      expect { subject }.to raise_error OresApi::InvalidProjectError
    end
  end

  describe '#get_revision_data' do
    let(:rev_ids) { [641962088, 12345] }
    let(:subject) { described_class.new(Wiki.find(1)).get_revision_data(rev_ids) }

    let(:first_id) { 641962088 }
    let(:last_id) { first_id + OresApi::REVS_PER_REQUEST - 1 }
    let(:many_rev_ids) { (first_id..last_id).to_a }

    it 'fetches json from ores.wikimedia.org' do
      VCR.use_cassette 'ores_api' do
        expect(subject).to be_a(Hash)
        expect(subject.dig('enwiki', 'scores', '12345', 'articlequality', 'features')).to be_a(Hash)
        expect(subject.dig('enwiki', 'scores', '641962088')).to be_a(Hash)
      end
    end

    it 'handles many revisions per request' do
      VCR.use_cassette 'ores_api' do
        result = described_class.new(Wiki.find(1)).get_revision_data(many_rev_ids)
        expect(result.dig('enwiki', 'scores').count).to eq(OresApi::REVS_PER_REQUEST)
      end
    end
  end
end
