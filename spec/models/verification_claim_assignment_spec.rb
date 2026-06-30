# frozen_string_literal: true

require 'rails_helper'

describe VerificationClaimAssignment do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:course) { create(:course) }
  let(:user) { create(:user) }
  let(:claim) { VerificationClaim.create!(wiki:, sentence: 'A claim.') }

  it 'allows one assignment per student per course' do
    described_class.create!(user:, course:, verification_claim: claim)
    dup = described_class.new(user:, course:, verification_claim: claim)
    expect(dup).not_to be_valid
  end

  it 'allows the same student an assignment in a different course' do
    other_course = create(:course, slug: 'Other/Course_x')
    described_class.create!(user:, course:, verification_claim: claim)
    second = described_class.new(user:, course: other_course, verification_claim: claim)
    expect(second).to be_valid
  end
end
