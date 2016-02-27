require 'spec_helper'

describe Rapidfire::Questions::Select do
  describe "Validations" do
    it { is_expected.to validate_presence_of(:answer_options) }
  end

  describe "#options" do
    let(:question)  { FactoryGirl.create(:q_select) }

    it "returns options" do
      expect(question.options).to match_array(["mac", "windows"])
    end
  end

  describe "validate_answer" do
    let(:question)  { FactoryGirl.create(:q_select, validation_rules: validation_rules) }
    let(:answer)    { FactoryGirl.build(:answer, question: question, answer_text: answer_text) }
    before  { answer.valid? }

    context "when there are no validation rules" do
      let(:validation_rules) { {} }
      let(:answer_text)      { "" }

      it "answer should pass validations" do
        expect(answer.errors).to be_empty
      end

      context "when there is an answer" do
        context "when answer is valid option" do
          let(:answer_text)   { "windows" }

          it "passes validation" do
            expect(answer.errors).to be_empty
          end
        end

        context "when answer is an invalid option" do
          let(:answer_text)   { "sample answer" }

          it "fails validation" do
            expect(answer.errors).not_to be_empty
          end

          it "says answer is invalid" do
            expect(answer.errors[:answer_text]).to include("is not included in the list")
          end
        end
      end
    end

    context "when question should have an answer" do
      let(:validation_rules) { { presence: "1" } }

      context "when answer is empty" do
        let(:answer_text)  { "" }

        it "fails validations" do
          expect(answer.errors).not_to be_empty
        end

        it "says answer should be present" do
          expect(answer.errors[:answer_text]).to include("can't be blank")
        end
      end

      context "when answer is not empty" do
        context "when answer is valid option" do
          let(:answer_text)   { "mac" }

          it "passes validation" do
            expect(answer.errors).to be_empty
          end
        end

        context "when answer is an invalid option" do
          let(:answer_text)   { "sample answer" }

          it "fails validation" do
            expect(answer.errors).not_to be_empty
          end

          it "says answer is invalid" do
            expect(answer.errors[:answer_text]).to include("is not included in the list")
          end
        end
      end
    end
  end
end
