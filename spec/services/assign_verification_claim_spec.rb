# frozen_string_literal: true

require 'rails_helper'

describe AssignVerificationClaim do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:course) { create(:course, subject: 'Ecology') }
  let(:student) { create(:user, username: 'Student1') }

  def claim(subject: 'Ecology', sentence: 'A claim.', article_id: nil)
    VerificationClaim.create!(wiki:, sentence:, subject:, article_id:)
  end

  it 'assigns a claim matching the course subject' do
    claim(subject: 'History', sentence: 'Off topic.')
    on_topic = claim(subject: 'Ecology', sentence: 'On topic.')
    assignment = described_class.new(user: student, course:).assignment
    expect(assignment.verification_claim).to eq(on_topic)
  end

  it 'returns the same assignment on repeat calls (stable per student)' do
    claim
    first = described_class.new(user: student, course:).assignment
    second = described_class.new(user: student, course:).assignment
    expect(second).to eq(first)
  end

  it 'does not assign the same claim to two students in one course' do
    claim(sentence: 'First.')
    claim(sentence: 'Second.')
    one = described_class.new(user: student, course:).assignment
    other = described_class.new(user: create(:user, username: 'Student2'), course:).assignment
    expect(other.verification_claim).not_to eq(one.verification_claim)
  end

  it 'falls back to the general pool when no subject match exists' do
    only = claim(subject: 'History', sentence: 'Different subject.')
    assignment = described_class.new(user: student, course:).assignment
    expect(assignment.verification_claim).to eq(only)
  end

  it 'falls back to the course article pool when no subject match exists' do
    otter = create(:article, wiki:, title: 'Otter', namespace: Article::Namespaces::MAINSPACE)
    category = create(:category, wiki_id: wiki.id, article_titles: ['Otter'])
    create(:categories_courses, course:, category:)
    claim(subject: 'History', sentence: 'General history.') # general pool, lower id
    in_pool = claim(subject: 'History', sentence: 'About otters.', article_id: otter.id)
    assignment = described_class.new(user: student, course:).assignment
    expect(assignment.verification_claim).to eq(in_pool)
  end

  it 'returns no assignment when the pool is empty' do
    expect(described_class.new(user: student, course:).assignment).to be_nil
  end

  describe 'reassign: true' do
    it 'switches to a different claim without creating a second assignment' do
      claim(sentence: 'First.')
      claim(sentence: 'Second.')
      first = described_class.new(user: student, course:).assignment.verification_claim
      switched = described_class.new(user: student, course:, reassign: true).assignment
      expect(switched.verification_claim).not_to eq(first)
      expect(VerificationClaimAssignment.where(user: student, course:).count).to eq(1)
    end

    it 'keeps the current claim when no other is available' do
      only = claim(sentence: 'Only one.')
      described_class.new(user: student, course:)
      switched = described_class.new(user: student, course:, reassign: true).assignment
      expect(switched.verification_claim).to eq(only)
    end

    it 'walks forward through the pool instead of bouncing between two claims' do
      first = claim(sentence: 'One.')
      second = claim(sentence: 'Two.')
      third = claim(sentence: 'Three.')
      seen = Array.new(3) do
        described_class.new(user: student, course:, reassign: true).assignment.verification_claim
      end
      expect(seen).to eq([first, second, third])
    end
  end
end
