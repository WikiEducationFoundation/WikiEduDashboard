require 'spec_helper'

describe "Question Groups" do
  let(:question_group)  { FactoryGirl.create(:question_group, name: "Question Set") }
  let(:question1)  { FactoryGirl.create(:q_long,  question_group: question_group, question_text: "Long Question", validation_rules: { presence: "1" })  }
  let(:question2)  { FactoryGirl.create(:q_short, question_group: question_group, question_text: "Short Question") }
  before do
    [question1, question2]
    visit rapidfire.new_question_group_answer_group_path(question_group)
  end

  describe "Answering Questions" do
    context "when all questions are answered" do
      before do
        fill_in "answer_group_#{question1.id}_answer_text", with: "Long Answer"
        fill_in "answer_group_#{question2.id}_answer_text", with: "Short Answer"
        click_button "Save"
      end

      it "persists 2 answers" do
        expect(Rapidfire::Answer.count).to eq(2)
      end

      it "persists 2 answers with answer values" do
        expected_answers = ["Long Answer", "Short Answer"]
        expect(Rapidfire::Answer.all.map(&:answer_text)).to match(expected_answers)
      end

      it "redirects to question groups path" do
        expect(current_path).to eq(rapidfire.question_groups_path)
      end
    end

    context "when all questions are not answered" do
      before do
        fill_in "answer_group_#{question1.id}_answer_text", with: ""
        fill_in "answer_group_#{question2.id}_answer_text", with: "Short Answer"
        click_button "Save"
      end

      it "fails to persits answers" do
        expect(Rapidfire::Answer.count).to eq(0)
      end

      it "shows error for missing answers" do
        expect(page).to have_content "can't be blank"
      end

      it "shows already populated answers" do
        short_answer = page.find("#answer_group_#{question2.id}_answer_text").value
        expect(short_answer).to have_content "Short Answer"
      end
    end
  end
end
