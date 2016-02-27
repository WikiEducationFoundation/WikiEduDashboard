require 'spec_helper'

describe Rapidfire::Questions::Date do
  describe "validate_answer" do
    let(:question)  { FactoryGirl.create(:q_date, validation_rules: validation_rules) }
    let(:answer)    { FactoryGirl.build(:answer, question: question, answer_text: answer_text) }
    before  { answer.valid? }

    context "when there are no validation rules" do
      let(:validation_rules) { {} }
      let(:answer_text)      { "" }

      it "answer should pass validations" do
        expect(answer.errors).to be_empty
      end

      context "when there is an answer" do
        context "when answer is valid date" do
          let(:answer_text)   { Date.today.to_s }

          it "passes validation" do
            expect(answer.errors).to be_empty
          end
        end

        context "when answer is invalid date" do
          let(:answer_text)   { "sample answer" }

          it "fails validation" do
            expect(answer.errors).not_to be_empty
          end

          it "says answer is invalid" do
            expect(answer.errors[:answer_text]).to include("is invalid")
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
        context "when answer is valid date" do
          let(:answer_text)   { Date.today.to_s }

          it "passes validation" do
            expect(answer.errors).to be_empty
          end
        end

        context "when answer is invalid date" do
          let(:answer_text)   { "sample answer" }

          it "fails validation" do
            expect(answer.errors).not_to be_empty
          end

          it "says answer is invalid" do
            expect(answer.errors[:answer_text]).to include("is invalid")
          end
        end
      end
    end
  end
end
