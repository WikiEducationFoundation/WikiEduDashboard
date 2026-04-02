# frozen_string_literal: true

require 'rails_helper'

describe 'Survey Administration', type: :feature, js: true do
  let(:admin) { create(:admin) }
  let(:campaign) { create(:campaign) }
  let(:course) { create(:course) }
  let(:instructor) { create(:user) }
  let(:courses_user) do
    create(:courses_user, user: instructor, course: course,
           role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
  end

  before do
    course.campaigns << campaign
    courses_user
    login_as(admin)
  end

  describe 'viewing survey results' do
    let(:survey) { create(:survey) }
    let(:answer) { create(:answer, follow_up_answer_text: 'yes') }

    before do
      survey_assignment = create(:survey_assignment, survey: survey)
      create(:survey_notification, survey_assignment: survey_assignment,
             courses_users_id: courses_user.id)
      survey.rapidfire_question_groups << answer.question.question_group
      answer.question.update(track_sentiment: true, answer_options: 'foo')
      answer.answer_group.update(user: instructor)
    end

    it 'shows the results index and individual survey results with CSV downloads' do
      visit '/surveys/results'
      expect(page).to have_content survey.name

      visit "/survey/results/#{survey.id}"
      expect(page).to have_content 'Average Sentiment'
      click_link 'Download Survey Results CSV'
      click_link 'Download Results CSV'
    end
  end

  describe 'managing survey responses' do
    let(:survey) { create(:survey) }
    let(:answer) { create(:answer) }

    before do
      survey_assignment = create(:survey_assignment, survey: survey)
      create(:survey_notification, survey_assignment: survey_assignment,
             courses_users_id: courses_user.id)
      survey.rapidfire_question_groups << answer.question.question_group
      answer.answer_group.update(user: instructor)
    end

    it 'lists responses and allows deletion' do
      visit '/survey/responses'
      expect(page).to have_content instructor.username
      accept_confirm { click_link 'Delete' }
      expect(page).not_to have_content instructor.username
    end
  end

  describe 'managing surveys' do
    it 'creates a survey and clones a question' do
      visit '/surveys'
      click_link 'New Survey'
      fill_in('survey_name', with: 'Test Survey')
      click_button 'Create Survey'
      expect(page).to have_content 'Survey was successfully created.'

      question_group = create(:question_group)
      question = create(:q_long, question_group: question_group)
      visit rapidfire.question_group_questions_path(question_group)
      within "tr[data-item-id=\"#{question.id}\"]" do
        click_link 'Clone'
      end
      expect(page).to have_content '(Copy) Long Text Question'
    end
  end

  describe 'managing survey assignments' do
    let(:survey) { create(:survey) }

    it 'creates, triggers notifications, edits, and deletes an assignment' do
      survey # ensure record exists before the page renders
      visit '/surveys/assignments'
      click_link 'New Survey Assignment'
      select survey.name, from: 'survey_assignment_survey_id'
      check 'survey_assignment_published'
      fill_in 'survey_assignment_custom_email_subject', with: 'Test Subject'
      find('input.button.dark').click
      expect(page).to have_content survey.name

      click_link 'Create Notifications'
      expect(page).to have_content 'Creating Survey Notifications'

      click_link 'Send Emails'
      expect(page).to have_content 'Sending Email Survey Notifications'

      visit '/surveys'
      expect(page).to have_content 'In Use'

      visit '/surveys/assignments'
      click_link 'Edit'
      expect(page).to have_field('survey_assignment_custom_email_subject', with: 'Test Subject')
      find('input.button.dark').click
      expect(page).to have_content survey.name

      click_link 'Edit'
      accept_confirm { click_link 'Delete Survey Assignment' }
      expect(page).not_to have_content survey.name
    end
  end

  describe 'deleting a survey' do
    let(:survey) { create(:survey) }

    it 'deletes a survey from its edit page' do
      visit "/surveys/#{survey.id}/edit"
      accept_confirm { click_link 'Delete this survey' }
      expect(page).to have_content 'Survey was successfully destroyed.'
    end
  end

  describe 'deleting a question group' do
    let(:question_group) { create(:question_group) }

    it 'deletes a question group from its edit page' do
      visit rapidfire.edit_question_group_path(question_group)
      accept_confirm { click_link 'Delete Question Group' }
      expect(page).to have_current_path rapidfire.question_groups_path
    end
  end

  describe 'cloning a question group with conditional questions' do
    it 'correctly updates conditionals to point to the cloned questions' do
      visit 'surveys/rapidfire/question_groups'
      click_link 'New Question Group'
      fill_in('question_group_name', with: 'Ice Cream Survey')
      page.find('input.button[value="Save Question Group"]').click

      click_link 'Edit'
      omniclick(find('a.button', text: 'Add New Question'))
      find('textarea#question_text').set('Do you like ice cream?')
      find('textarea#question_answer_options').set("Yes\nNo")
      page.find('input.button').click

      omniclick(find('a.button', text: 'Add New Question'))
      find('textarea#question_text').set('What is your favorite flavor?')
      find('textarea#question_answer_options').set("Vanilla\nChocolate")
      page.find('label', text: 'Conditionally show this question').click

      first_q = Rapidfire::Question.find_by(question_text: 'Do you like ice cream?')
      within('.survey__question__conditional-row') do
        page.execute_script(
          "arguments[0].selected = true;
          arguments[0].parentNode.dispatchEvent(new Event('change'))",
          find("select[data-conditional-select='true'] option",
               text: first_q.question_text).native
        )
        find('select[data-conditional-value-select=""]')
          .select(first_q.answer_options[/^\s*Yes\b/])
      end
      page.find('input.button').click

      click_link 'Question Groups'
      within("li#question_group_#{Rapidfire::QuestionGroup.last.id}") do
        click_link 'Clone'
      end
      expect(page).to have_content 'Ice Cream Survey (Copy)'

      cloned_group = Rapidfire::QuestionGroup.last
      expect(cloned_group.name).to eq('Ice Cream Survey (Copy)')
      cloned_first_q = cloned_group.questions.find_by(question_text: 'Do you like ice cream?')
      cloned_follow_up = cloned_group.questions
                                     .find_by(question_text: 'What is your favorite flavor?')
      expect(cloned_follow_up.conditionals).to include(cloned_first_q.id.to_s)

      within("li#question_group_#{cloned_group.id}") { click_link 'Edit' }
      within("tr[data-item-id=\"#{cloned_follow_up.id}\"]") { click_link 'Edit' }
      expect(page).to have_content 'What is your favorite flavor?'
    end
  end
end
