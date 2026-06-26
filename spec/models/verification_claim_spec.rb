# frozen_string_literal: true

require 'rails_helper'

describe VerificationClaim do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }

  it 'requires a sentence' do
    expect(described_class.new(wiki:, sentence: nil)).not_to be_valid
  end

  it 'can be tied to the AiEditAlert it was harvested from' do
    alert = create(:ai_edit_alert)
    claim = described_class.create!(wiki:, sentence: 'Harvested fact.', alert:)
    expect(claim.alert).to eq(alert)
  end

  describe '.for_subject' do
    it 'returns only claims tagged with the subject' do
      described_class.create!(wiki:, sentence: 'Ecology fact.', subject: 'Ecology')
      described_class.create!(wiki:, sentence: 'History fact.', subject: 'History')
      expect(described_class.for_subject('Ecology').map(&:sentence)).to eq(['Ecology fact.'])
    end
  end
end
