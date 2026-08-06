# frozen_string_literal: true

require 'rails_helper'

describe VerificationClaimResponse do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:course) { create(:course) }
  let(:user) { create(:user) }
  let(:claim) do
    VerificationClaim.create!(wiki:, sentence: 'Sea otters use rocks as tools.')
  end

  # Every question the exercise currently requires, answered.
  let(:complete_answers) do
    { 'source_appropriate' => 'appropriate', 'meets_rs_policy' => 'generally_reliable',
      'source_access' => 'accessed', 'verdict' => 'full_support' }
  end

  let(:base_attributes) do
    { user:, course:, verification_claim: claim, answers: complete_answers }
  end

  it 'is valid when every required question is answered' do
    expect(described_class.new(base_attributes)).to be_valid
  end

  it 'reads one answer by question id' do
    response = described_class.new(base_attributes)
    expect(response.answer('verdict')).to eq('full_support')
  end

  it 'has no answer for a question the exercise did not ask' do
    response = described_class.new(base_attributes)
    expect(response.answer('claim_location')).to be_nil
  end

  it 'rejects an answer outside the set its question offers' do
    answers = complete_answers.merge('source_access' => 'maybe')
    expect(described_class.new(base_attributes.merge(answers:))).not_to be_valid
  end

  it 'rejects a required question left unanswered' do
    answers = complete_answers.except('meets_rs_policy')
    expect(described_class.new(base_attributes.merge(answers:))).not_to be_valid
  end

  it 'rejects a response with no answers at all' do
    expect(described_class.new(base_attributes.merge(answers: {}))).not_to be_valid
  end

  # The verify-the-claim step is gated on having got the source, so its verdict
  # isn't required of a student who couldn't.
  it 'allows a no-source response without the verify-step answers' do
    answers = complete_answers.except('verdict')
                              .merge('source_access' => 'nonexistent',
                                     'source_access_notes' => 'No trace of it.')
    expect(described_class.new(base_attributes.merge(answers:))).to be_valid
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
