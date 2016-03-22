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

    it "should raise an error if answer_options aren't specified and no course data is set" do
      invalid_question = build(:q_radio, :answer_options => "")
      invalid_question.valid?
      expect(invalid_question.errors[:answer_options].size).to eq(1)

      valid_question = build(:q_radio, :course_data_type => "Students")
      valid_question.valid?
      expect(valid_question.errors[:answer_options].size).to eq(0)
    end

    it "should not raise an error if the question type has changed to one that doesn't require answer options" do
      valid_question = build(:q_radio, :course_data_type => "Students")
      valid_question.type = "Rapidfire::Questions::RangeInput"
      valid_question.answer_options = ""
      valid_question.valid?
      expect(valid_question.errors[:answer_options].size).to eq(0)
    end
  end
end