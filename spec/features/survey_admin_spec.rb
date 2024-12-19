# frozen_string_literal: true

require 'rails_helper'

describe 'Survey Administration', type: :feature, js: true do
  include Rapidfire::QuestionSpecHelper
  include Rapidfire::AnswerSpecHelper

  before do
    include type: :feature
    include Devise::TestHelpers
    page.current_window.resize_to(1920, 1080)
  end

  context 'an admin' do
    let(:instructor) { create(:user, email: 'instructor@school.edu') }

    before do
      admin = create(:admin)
      login_as admin
      course = create(:course)
      course.campaigns << Campaign.last
      course.courses_users << create(:courses_user, user_id: instructor.id, role: 1)
    end

    it 'can create a Survey and a SurveyAssignment' do
      pending 'This sometimes fails at the "Delete this survey" step for unknown reasons.'

      # Create the survey
      expect(Survey.count).to eq(0)
      visit '/surveys'
      click_link 'New Survey'
      fill_in('survey_name', with: 'Test Survey')
      page.find('input.button').click
      expect(page).to have_content 'Survey was successfully created.'
      expect(Survey.count).to eq(1)

      # Create a question group
      expect(Rapidfire::QuestionGroup.count).to eq(0)
      click_link 'Question Groups'
      click_link 'New Question Group'
      fill_in('question_group_name', with: 'New Question Group')

      # FIXME: Fails to find the div with Poltergeist
      # within('div#question_group_campaign_ids_chosen') do
      #   find('input').set('Spring 2015')
      #   find('input').native.send_keys(:return)
      # end
      page.find('input.button[value="Save Question Group"]').click

      # Create a question
      click_link 'Edit'
      expect(Rapidfire::QuestionGroup.count).to eq(1)
      expect(Rapidfire::Question.count).to eq(0)

      omniclick(find('a.button', text: 'Add New Question'))
      find('textarea#question_text').set('Who is awesome?')
      find('textarea#question_answer_options').set('Me!')
      page.find('input.button').click
      sleep 1
      expect(Rapidfire::Question.count).to eq(1)

      # Clone a question and make it conditional
      click_link 'Clone'
      within "tr[data-item-id=\"#{Rapidfire::Question.last.id}\"]" do
        click_link 'Edit'
      end
      expect(Rapidfire::Question.count).to eq(2)

      page.find('label', text: 'Conditionally show this question').click
      # FIXME: fails to find the div with Poltergeist
      # within 'div.survey__question__conditional-row' do
      #   select('Who is awesome?')
      # end
      # within 'select[data-conditional-value-select=""]' do
      #   select('Me!')
      # end
      page.find('input.button').click

      # Create two more question groups, so that we can reorder them.
      click_link 'Question Groups'
      click_link 'New Question Group'
      fill_in('question_group_name', with: 'Second Question Group')
      page.find('input.button[value="Save Question Group"]').click
      click_link 'Question Groups'
      click_link 'New Question Group'
      fill_in('question_group_name', with: 'Third Question Group')
      page.find('input.button[value="Save Question Group"]').click

      # Add a question groups to the survey
      visit '/surveys'
      click_link 'Edit'
      omniclick(find('a', text: 'Edit Question Groups'))
      Rapidfire::QuestionGroup.last(3).pluck(:id).each do |id|
        check "survey_rapidfire_question_group_ids_#{id}"
      end
      page.find('input.button').click

      # Reorder the question groups
      # This doesn't actually work, apparently because the 'drag_to' event happens
      # too fast for the javascript to treat it as a completed move.
      visit '/surveys'
      click_link 'Edit'

      group_id = Rapidfire::QuestionGroup.first.id
      drag_source = find("tr.question-group-row[data-item-id=\"#{group_id}\"]")
      drag_target = find('#survey_intro')
      drag_source.drag_to(drag_target)

      # Clone a Question Group
      visit '/surveys'
      click_link 'Question Groups'
      within "li#question_group_#{group_id}" do
        click_link 'Clone'
      end

      # Delete a Question Group
      within "li#question_group_#{group_id}" do
        click_link 'Edit'
      end
      page.accept_confirm do
        click_link 'Delete Question Group'
      end

      # Create a SurveyAssignment
      expect(SurveyAssignment.count).to eq(0)
      visit '/surveys/assignments'
      click_link 'New Survey Assignment'

      # FIXME: Fails to find the div with Poltergeist
      # within('div#survey_assignment_campaign_ids_chosen') do
      #   find('input').set('Spring 2015')
      #   find('input').native.send_keys(:return)
      # end
      fill_in('survey_assignment_send_date_days', with: '7')
      check 'survey_assignment_published'
      fill_in('survey_assignment_custom_email_subject', with: 'My Custom Subject!')
      fill_in('survey_assignment_custom_email_headline', with: 'My Custom Headline!')
      fill_in('survey_assignment_custom_email_body', with: 'My Custom Body!')
      fill_in('survey_assignment_custom_email_signature', with: 'My Custom Signature!')
      fill_in('survey_assignment_custom_banner_message', with: 'My Custom Banner!')

      page.find('input.button').click
      click_link 'Create Notifications'
      expect(SurveyAssignment.count).to eq(1)
      click_link 'Send Emails'

      # Update the SurveyAssignment
      click_link 'Edit'
      expect(page).to have_field('survey_assignment_custom_email_subject',
                                 with: 'My Custom Subject!')
      expect(page).to have_field('survey_assignment_custom_email_headline',
                                 with: 'My Custom Headline!')
      expect(page).to have_field('survey_assignment_custom_email_body',
                                 with: 'My Custom Body!')
      expect(page).to have_field('survey_assignment_custom_email_signature',
                                 with: 'My Custom Signature!')
      expect(page).to have_field('survey_assignment_custom_banner_message',
                                 with: 'My Custom Banner!')

      fill_in('survey_assignment_notes', with: 'This is a test.')
      page.find('input.button').click

      # Check that the survey is now "In Use"
      visit '/surveys'
      expect(page).to have_content 'In Use'

      # Check that the QuestionGroup is now "In Use"
      click_link 'Question Groups'
      expect(page).to have_content 'In Use'

      # Destroy the SurveyAssignment
      click_link 'Assignment'

      click_link 'Edit'
      page.accept_confirm do
        click_link 'Delete Survey Assignment'
      end

      # Destroy a survey
      visit "/surveys/#{Survey.last.id}/edit"
      expect(SurveyAssignment.count).to eq(0)

      page.accept_confirm do
        click_link 'Delete this survey'
      end
      sleep 1
      expect(Survey.count).to eq(0)

      pass_pending_spec
    end

    it 'can view survey results' do
      survey = create(:survey)
      survey_assignment = create(:survey_assignment, survey_id: survey.id)
      create(:survey_notification, survey_assignment_id: survey_assignment.id,
                                   courses_users_id: CoursesUsers.last.id)
      answer = create(:answer, follow_up_answer_text: 'yes')
      survey.rapidfire_question_groups << answer.question.question_group
      answer.question.update(track_sentiment: true, answer_options: 'foo')
      answer.answer_group.update(user_id: instructor.id)
      visit '/surveys/results'
      visit "/survey/results/#{Survey.last.id}"
      expect(page).to have_content 'Average Sentiment'
      click_link 'Download Survey Results CSV'
      click_link 'Download Results CSV'
    end

    it 'can delete a survey response' do
      survey = create(:survey)
      survey_assignment = create(:survey_assignment, survey_id: survey.id)
      create(:survey_notification, survey_assignment_id: survey_assignment.id,
                                   courses_users_id: CoursesUsers.last.id)
      answer = create(:answer)
      survey.rapidfire_question_groups << answer.question.question_group
      answer.question.update(track_sentiment: true, answer_options: 'foo')
      answer.answer_group.update(user_id: instructor.id)
      visit '/survey/responses'
      expect(page).to have_content instructor.username
      accept_confirm do
        click_link 'Delete'
      end
      expect(page).not_to have_content instructor.username
    end

    it 'correctly clones question groups with conditional questions', js: true do
      # Create a base question group with conditional questions

      # Visit question groups page and create Question Group
      visit 'surveys/rapidfire/question_groups'
      click_link 'New Question Group'
      fill_in('question_group_name', with: 'Conditional Questions Group')
      page.find('input.button[value="Save Question Group"]').click

      # Create the first question
      click_link 'Edit'
      omniclick(find('a.button', text: 'Add New Question'))
      first_question_text = 'Do you like ice cream?'
      find('textarea#question_text').set(first_question_text)
      find('textarea#question_answer_options').set("Yes\nNo")
      page.find('input.button').click

      # Create a conditional follow-up question
      omniclick(find('a.button', text: 'Add New Question'))
      follow_up_question_text = 'What is your favorite flavor?'
      find('textarea#question_text').set(follow_up_question_text)
      find('textarea#question_answer_options').set("Vanilla\nChocolate")

      # Set conditional logic
      page.find('label', text: 'Conditionally show this question').click

      # Wait and verify the conditional elements are present
      first_question_record = Rapidfire::Question.find_by(question_text: first_question_text)

      # Interact with conditional elements
      within('.survey__question__conditional-row') do
        # Trigger the conditional select to populate options
        page.find('select[data-conditional-select="true"]').click

        # Wait for and select the first question
        option = page.find('select[data-conditional-select="true"] option',
                           text: first_question_record.question_text)
        page.execute_script(
          "arguments[0].selected = true;
          arguments[0].parentNode.dispatchEvent(new Event('change'))", option.native
        )

        # Select the condition value
        find('select[data-conditional-value-select=""]')
          .select(first_question_record.answer_options[/^\s*Yes\b/])
      end

      # Verify the hidden input has been populated correctly
      hidden_input = page.find('input[data-conditional-field-input="true"]', visible: false)
      # rubocop:disable Layout/LineLength,Lint/MissingCopEnableDirective
      expected_conditionals = "#{first_question_record.id}|=|#{first_question_record.answer_options[/^\s*Yes\b/]}|multi"
      expect(hidden_input.value).to include(expected_conditionals)

      page.find('input.button').click

      # Visit the question groups page to clone the newly created question group
      visit 'surveys/rapidfire/question_groups'

      # Find and click the clone link for the newly created question group
      within("li#question_group_#{Rapidfire::QuestionGroup.last.id}") do
        click_link 'Clone'
      end

      # Edit the cloned question group
      within("li#question_group_#{Rapidfire::QuestionGroup.last.id}") do
        click_link 'Edit'
      end

      # Edit the conditional question of the cloned group
      within "tr[data-item-id=\"#{Rapidfire::Question.last.id}\"]" do
        click_link 'Edit'
      end

      # Verify manually to check if the cloned group exists
      expect(Rapidfire::QuestionGroup.count).to eq(2)
      cloned_group = Rapidfire::QuestionGroup.last

      # Verify questions were cloned
      expect(cloned_group.questions.count).to eq(2)

      # Check the conditional question
      conditional_question = cloned_group.questions.detect { |q| q.question_text == follow_up_question_text }
      expect(conditional_question).not_to be_nil

      # Verify the conditional logic points to the cloned first question
      cloned_first_question = cloned_group.questions.detect do |q|
        q.question_text == first_question_text
      end
      expected_cloned_conditionals = "#{cloned_first_question.id}|=|#{cloned_first_question.answer_options[/^\s*Yes\b/]}|multi"
      expect(conditional_question.conditionals).to eq(expected_cloned_conditionals)
    end
  end
end
