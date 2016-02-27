require 'spec_helper'

describe "Question Groups" do
  include Rapidfire::QuestionSpecHelper
  include Rapidfire::AnswerSpecHelper

  let(:question_group)  { FactoryGirl.create(:question_group, name: "Question Set") }
  let(:question1)  { FactoryGirl.create(:q_long,  question_group: question_group, question_text: "Long Question")  }
  let(:question2)  { FactoryGirl.create(:q_short, question_group: question_group, question_text: "Short Question") }
  before do
    [question1, question2]
  end

  describe "INDEX Question Groups" do
    before do
      visit rapidfire.root_path
    end

    it "lists all question groups" do
      expect(page).to have_content question_group.name
    end
  end

  describe "DELETE Question Groups" do
    context "when user can administer" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:can_administer?).and_return(true)

        visit rapidfire.root_path
        click_link "Delete"
      end

      it "deletes the question group" do
        expect(page).not_to have_content question_group.name
      end
    end

    context "when user cannot administer" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:can_administer?).and_return(false)
        visit rapidfire.root_path
      end

      it "doesn't show option to delete question group" do
        expect(page).not_to have_link "Delete"
      end
    end
  end

  describe "CREATING Question Group" do
    context "when user can create groups" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:can_administer?).and_return(true)

        visit rapidfire.root_path
        click_link "New Group"
      end

      context "when name is present" do
        before do
          page.within("#new_question_group") do
            fill_in "question_group_name", with: "New Survey"
            click_button "Create Question group"
          end
        end

        it "creates question group" do
          expect(page).to have_content "New Survey"
        end
      end

      context "when name is not present" do
        before do
          page.within("#new_question_group") do
            click_button "Create Question group"
          end
        end

        it "fails to create question group" do
          page.within("#new_question_group") do
            expect(page).to have_content "can't be blank"
          end
        end
      end
    end

    context "when user cannot create groups" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:can_administer?).and_return(false)
        visit rapidfire.root_path
      end

      it "page shouldnot have link to create groups" do
        expect(page).not_to have_link "New Group"
      end
    end
  end

  describe "EDITING Question Groups" do
    context "when user can manage questions" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:can_administer?).and_return(true)

        visit rapidfire.root_path
        click_link question_group.name
      end

      it "shows set of questions" do
        expect(page).to have_content question1.question_text
        expect(page).to have_content question2.question_text
      end
    end

    context "when user cannot manage questions" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:can_administer?).and_return(false)
      end

      it "fails to access the page" do
        expect(page).not_to have_link question_group.name
      end
    end
  end

  describe "GET Question Group results" do
    before do
      create_questions(question_group)
      create_answers

      visit rapidfire.root_path
      page.within("#question_group_#{question_group.id}") do
        click_link "Results"
      end
    end

    it "shows results for particular question group" do
      expect(page).to have_content "Results"
      expect(page).to have_content "hindi 3"
    end
  end
end
