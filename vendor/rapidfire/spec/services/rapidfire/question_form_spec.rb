require 'spec_helper'

describe Rapidfire::QuestionForm do
  let(:question_group)  { FactoryGirl.create(:question_group) }

  describe "Creation" do
    let(:proxy)  { described_class.new(question_group: question_group) }

    it "builds a dummy question" do
      expect(proxy.question).not_to be_nil
    end

    context "when params are passed" do
      let(:proxy)  { described_class.new(question_group: question_group, question_text: "Your Bio") }

      it "persists those params" do
        expect(proxy.question_text).to eq("Your Bio")
      end
    end

    context "when a question is passed" do
      let(:question)  { FactoryGirl.create(:q_checkbox, question_group: question_group) }
      let(:proxy)     { described_class.new(question_group: question_group, question: question) }

      it "persists question params" do
        expect(proxy.type).to eq(question.type)
        expect(proxy.question_group).to eq(question.question_group)
        expect(proxy.question_text).to  eq(question.question_text)
        expect(proxy.answer_options).to eq(question.answer_options)
      end
    end
  end

  describe "#save" do
    before  { proxy.save }

    context "creating a new question" do
      let(:proxy) { described_class.new(params.merge(question_group: question_group)) }

      context "when question params are valid" do
        let(:params) do
          {
            type:           "Rapidfire::Questions::Checkbox",
            question_text:  "Your mood today",
            answer_options: "good\r\nbad"
          }
        end

        it "persists the question" do
          expect(proxy.errors).to be_empty
        end

        it "creates a question given type" do
          expect(proxy.question).to be_a(Rapidfire::Questions::Checkbox)
        end

        it "persists params in created question" do
          expect(proxy.question.question_text).to eq("Your mood today")
          expect(proxy.question.options).to match_array(["good", "bad"])
        end
      end

      context "when question params are invalid" do
        let(:params) do
          { type: "Rapidfire::Questions::Checkbox" }
        end

        it "fails to presist the question" do
          expect(proxy.errors).not_to be_empty
          expect(proxy.errors[:question_text]).to  include("can't be blank")
          expect(proxy.errors[:answer_options]).to include("can't be blank")
        end
      end
    end

    context "updating a question" do
      let(:question)  { FactoryGirl.create(:q_checkbox, question_group: question_group) }
      let(:proxy) do
        proxy_params = params.merge(question_group: question_group, question: question)
        described_class.new(proxy_params)
      end

      let(:params) do
        { question_text: "Changing question text" }
      end

      it "updates the question" do
        expect(proxy.errors).to be_empty
        expect(proxy.question.question_text).to eq("Changing question text")
      end
    end
  end
end
