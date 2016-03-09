require 'rails_helper'

describe Rapidfire::Question do
  describe 'Matrix Question Creation' do
    it 'should create create a question' do
      question = create(:matrix_question)
      expect(Rapidfire::Question.last.question_text).to eq('Question?')
    end

    it 'should raise an error if the question type is not an available type for matrix questions' do
      invalid_question = build(:matrix_question, type: "Rapidfire::Questions::Long")
      invalid_question.valid?
      expect(invalid_question.errors[:type].size).to eq(1)
    end
  end
end