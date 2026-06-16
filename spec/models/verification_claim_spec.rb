# frozen_string_literal: true

require 'rails_helper'

describe VerificationClaim do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }

  it 'requires a sentence' do
    expect(described_class.new(wiki:, sentence: nil)).not_to be_valid
  end

  describe '.for_subject' do
    it 'returns only claims tagged with the subject' do
      described_class.create!(wiki:, sentence: 'Ecology fact.', subject: 'Ecology')
      described_class.create!(wiki:, sentence: 'History fact.', subject: 'History')
      expect(described_class.for_subject('Ecology').map(&:sentence)).to eq(['Ecology fact.'])
    end
  end

  describe '.student_added' do
    it 'returns only claims linked to a courses_user' do
      course = create(:course)
      courses_user = create(:courses_user, course:, user: create(:user))
      added = described_class.create!(wiki:, sentence: 'Added by a student.',
                                      courses_user:)
      described_class.create!(wiki:, sentence: 'Pre-existing.')
      expect(described_class.student_added).to eq([added])
    end
  end
end
