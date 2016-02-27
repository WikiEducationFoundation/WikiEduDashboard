require 'spec_helper'

describe Rapidfire::Answer do
  describe "Validations" do
    subject { FactoryGirl.build(:answer) }
    it { is_expected.to validate_presence_of(:question)      }
    it { is_expected.to validate_presence_of(:answer_group)  }

    context "when validations are run" do
      let(:answer)  { FactoryGirl.build(:answer) }

      it "delegates validation of answer text to question" do
        expect(answer.question).to receive(:validate_answer).with(answer).once
        expect(answer.valid?).to be_truthy
      end
    end
  end

  describe "Associations" do
    it { is_expected.to belong_to(:question)     }
    it { is_expected.to belong_to(:answer_group) }
  end
end
