# frozen_string_literal: true

require 'rails_helper'

describe VerificationClaimResponse do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:course) { create(:course) }
  let(:user) { create(:user) }
  let(:claim) do
    VerificationClaim.create!(wiki:, sentence: 'Sea otters use rocks as tools.')
  end

  let(:base_attributes) do
    { user:, course:, verification_claim: claim, source_access: 'accessed',
      verdict: 'full_support' }
  end

  it 'is valid with an accessed source and a verdict' do
    expect(described_class.new(base_attributes)).to be_valid
  end

  it 'rejects a source_access value outside the answer set' do
    response = described_class.new(base_attributes.merge(source_access: 'maybe'))
    expect(response).not_to be_valid
  end

  it 'requires a verdict when the source was accessed' do
    response = described_class.new(base_attributes.merge(verdict: nil))
    expect(response).not_to be_valid
  end

  it 'rejects a verdict outside the answer set' do
    response = described_class.new(base_attributes.merge(verdict: 'sort_of'))
    expect(response).not_to be_valid
  end

  it 'rejects a verdict when the source could not be accessed' do
    response = described_class.new(base_attributes.merge(source_access: 'inaccessible'))
    expect(response).not_to be_valid
  end

  it 'allows a no-source response without a verdict' do
    response = described_class.new(base_attributes.merge(source_access: 'nonexistent',
                                                         verdict: nil,
                                                         source_access_notes: 'No trace of it.'))
    expect(response).to be_valid
  end

  it 'allows only one response per claim per student' do
    described_class.create!(base_attributes)
    duplicate = described_class.new(base_attributes)
    expect(duplicate).not_to be_valid
  end

  it 'allows the same student to respond to multiple claims in a course' do
    described_class.create!(base_attributes)
    other_claim = VerificationClaim.create!(wiki:, sentence: 'Another claim.')
    second = described_class.new(base_attributes.merge(verification_claim: other_claim))
    expect(second).to be_valid
  end
end
