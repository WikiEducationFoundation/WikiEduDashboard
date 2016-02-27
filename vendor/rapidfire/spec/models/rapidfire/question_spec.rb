require 'spec_helper'

describe Rapidfire::Question do
  describe "Validations" do
    it { is_expected.to validate_presence_of(:question_group) }
    it { is_expected.to validate_presence_of(:question_text)  }
  end

  describe "Associations" do
    it { is_expected.to belong_to(:question_group) }
  end

  describe "#rules" do
    let(:question)  { FactoryGirl.create(:q_long, validation_rules: validation_rules) }

    context "when there are no validation rules" do
      let(:validation_rules) { {} }

      it "returns empty hash" do
        expect(question.rules).to be_empty
      end
    end

    context "when validation rules are present" do
      let(:validation_rules) do
        { :presence => "1" }
      end

      it "returns those rules" do
        expect(question.rules[:presence]).to be_truthy
      end
    end
  end

  describe "validate_answer" do
    let(:question)  { FactoryGirl.create(:q_long, validation_rules: validation_rules) }
    let(:answer)    { FactoryGirl.build(:answer, question: question, answer_text: answer_text) }
    before  { answer.valid? }

    context "when there are no validation rules" do
      let(:validation_rules) { {} }
      let(:answer_text)      { "" }

      it "answer should pass validations" do
        expect(answer.errors).to be_empty
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
        let(:answer_text)  { "sample answer" }

        it "passes validations" do
          expect(answer.errors).to be_empty
        end
      end
    end

    context "when question should have an answer with min or max length" do
      let(:validation_rules) { { minimum: "10", maximum: "20" } }

      context "when answer is empty" do
        let(:answer_text)  { "" }

        it "fails validations" do
          expect(answer.errors).not_to be_empty
        end

        it "says answer is too short" do
          expect(answer.errors[:answer_text].first).to match("is too short")
        end
      end

      context "when answer is not empty" do
        context "when answer is less than min chars" do
          let(:answer_text)  { 'i' * 9 }

          it "fails validations" do
            expect(answer.errors).not_to be_empty
          end

          it "says answer is too short" do
            expect(answer.errors[:answer_text].first).to match("is too short")
          end
        end

        context "when answer is in between min and max chars" do
          let(:answer_text)  { 'i' * 15 }

          it "passes validations" do
            expect(answer.errors).to be_empty
          end
        end

        context "when answer is more than max chars" do
          let(:answer_text)  { 'i' * 21 }

          it "fails validations" do
            expect(answer.errors).not_to be_empty
          end

          it "says answer is too long" do
            expect(answer.errors[:answer_text].first).to match("is too long")
          end
        end
      end
    end
  end
end
