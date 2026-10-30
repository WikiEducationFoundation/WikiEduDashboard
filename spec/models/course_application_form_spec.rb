# frozen_string_literal: true

require 'rails_helper'

describe CourseApplicationForm do
  let(:course) { create(:fellows_cohort) }
  let(:base_group) { create(:question_group, name: 'Base') }
  let(:theme_group) { create(:question_group, name: 'Theme') }

  describe 'validations' do
    it 'accepts a Scholars & Scientists course' do
      expect(described_class.new(course:)).to be_valid
    end

    it 'refuses a course type that does not take applications' do
      form = described_class.new(course: create(:course))
      expect(form).not_to be_valid
      expect(form.errors[:course]).to be_present
    end

    it 'allows one form per course' do
      described_class.create!(course:)
      expect(described_class.new(course:)).not_to be_valid
    end

    it 'refuses to open with no question groups' do
      form = described_class.new(course:, open: true)
      expect(form).not_to be_valid
      expect(form.errors[:base]).to be_present
    end

    it 'opens once it has a question group' do
      expect(described_class.new(course:, open: true, question_group_ids: [base_group.id]))
        .to be_valid
    end

    it 'refuses question group ids that do not exist' do
      form = described_class.new(course:, question_group_ids: [base_group.id, 999_999])
      expect(form).not_to be_valid
      expect(form.errors[:question_group_ids]).to be_present
    end

    # Keeps a group's answers coming only from applications.
    it 'refuses a question group that is used in a survey' do
      create(:survey).rapidfire_question_groups << base_group
      form = described_class.new(course:, question_group_ids: [base_group.id])
      expect(form).not_to be_valid
      expect(form.errors[:question_group_ids]).to be_present
    end
  end

  describe 'question_group_ids' do
    it 'normalizes form params to unique integer ids, keeping their order' do
      ids = [theme_group.id.to_s, '', base_group.id.to_s, theme_group.id.to_s]
      form = described_class.create!(course:, question_group_ids: ids)
      expect(form.reload.question_group_ids).to eq([theme_group.id, base_group.id])
    end
  end

  describe '#question_groups' do
    it 'returns the groups in form order' do
      form = described_class.create!(course:, question_group_ids: [theme_group.id, base_group.id])
      expect(form.question_groups).to eq([theme_group, base_group])
    end
  end

  describe '.uses_question_group?' do
    it 'is true for a group on any course form' do
      described_class.create!(course:, question_group_ids: [base_group.id])
      expect(described_class.uses_question_group?(base_group.id)).to be true
      expect(described_class.uses_question_group?(theme_group.id)).to be false
    end
  end

  it 'is deleted with its course' do
    described_class.create!(course:)
    course.destroy
    expect(described_class.count).to eq(0)
  end
end
