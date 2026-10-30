# frozen_string_literal: true

require 'rails_helper'

describe CourseApplication do
  let(:course) { create(:fellows_cohort) }
  let(:user) { create(:user) }

  it 'starts as submitted' do
    expect(described_class.create!(course:, user:)).to be_submitted
  end

  it 'allows one application per person per course' do
    described_class.create!(course:, user:)
    expect(described_class.new(course:, user:)).not_to be_valid
  end

  describe 'when destroyed' do
    let(:application) { described_class.create!(course:, user:) }
    let(:question) { create(:q_long) }

    before do
      answer_group = Rapidfire::AnswerGroup.create!(question_group: question.question_group, user:,
                                                    course_application: application)
      Rapidfire::Answer.create!(answer_group:, question:, answer_text: 'An answer')
    end

    # Rapidfire answer groups don't destroy their own answers.
    it 'takes its answer groups and their answers with it' do
      application.destroy
      expect(Rapidfire::AnswerGroup.count).to eq(0)
      expect(Rapidfire::Answer.count).to eq(0)
    end

    it 'is destroyed with its course' do
      course.destroy
      expect(described_class.count).to eq(0)
      expect(Rapidfire::Answer.count).to eq(0)
    end
  end
end
