# frozen_string_literal: true

require 'rails_helper'

describe Rapidfire::Question do
  describe 'Answer Options Validation' do
    it "raises an error if answer_options aren't specified and no course data is set" do
      invalid_question = build(:q_radio, answer_options: '')
      invalid_question.valid?
      expect(invalid_question.errors[:answer_options].size).to eq(1)

      valid_question = build(:q_radio, course_data_type: 'Students')
      valid_question.valid?
      expect(valid_question.errors[:answer_options].size).to eq(0)
    end

    it 'does not raise an error if the question type has changed to one that doesn't require answer options" do
      valid_question = build(:q_radio, course_data_type: 'Students')
      valid_question.type = 'Rapidfire::Questions::RangeInput'
      valid_question.answer_options = ''
      valid_question.valid?
      expect(valid_question.errors[:answer_options].size).to eq(0)
    end
  end

  describe 'Matrix Question Creation' do
    it 'creates create a question' do
      create(:matrix_question)
      expect(described_class.last.question_text).to eq('Question?')
    end

    it 'raises an error if the question type is not an available type for matrix questions' do
      invalid_question = build(:matrix_question, type: 'Rapidfire::Questions::Long')
      invalid_question.valid?
      expect(invalid_question.errors[:type].size).to eq(1)
    end
  end

  describe 'Reordering Questions' do
    before do
      @question_group = create(:question_group)
      @question1 = create(:q_short, question_group: @question_group)
      @question2 = create(:q_short, question_group: @question_group)
      @question3 = create(:q_short, question_group: @question_group)
    end

    it 'is placed at the bottom of the list on create' do
      expect(@question3.position).to eq(3)
    end

    it 'has position 1 if move to top of list' do
      @question3.insert_at(1)
      expect(@question3.position).to eq(1)
    end
  end
end
