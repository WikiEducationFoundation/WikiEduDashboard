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
    before do
      admin = create(:admin)
      login_as admin
    end

    let(:instructor) { create(:user, email: 'instructor@school.edu') }

    before do
      course = create(:course)
      course.campaigns << Campaign.last
      course.courses_users << create(:courses_user, user_id: instructor.id, role: 1)
    end

    it 'can create a Survey and a SurveyAssignment' do
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
      sleep 1
      expect(Rapidfire::QuestionGroup.count).to eq(1)

      # Create a question
      expect(Rapidfire::Question.count).to eq(0)
      click_link 'Edit'
      omniclick(find('a.button', text: 'Add New Question'))
      find('textarea#question_text').set('Who is awesome?')
      find('textarea#question_answer_options').set('Me!')
      page.find('input.button').click
      sleep 1
      expect(Rapidfire::Question.count).to eq(1)

      # Clone a question and make it conditional
      click_link 'Clone'
      sleep 1
      expect(Rapidfire::Question.count).to eq(2)
      within 'tr[data-item-id="2"]' do
        click_link 'Edit'
      end

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
      check 'survey_rapidfire_question_group_ids_1'
      check 'survey_rapidfire_question_group_ids_2'
      check 'survey_rapidfire_question_group_ids_3'
      page.find('input.button').click

      # Reorder the question groups
      # This doesn't actually work, apparently because the 'drag_to' event happens
      # too fast for the javascript to treat it as a completed move.
      visit '/surveys'
      click_link 'Edit'
      drag_source = find('tr.question-group-row[data-item-id="1"]')
      drag_target = find('#survey_intro')
      drag_source.drag_to(drag_target)

      # Clone a Question Group
      visit '/surveys'
      click_link 'Question Groups'
      within 'li#question_group_1' do
        click_link 'Clone'
      end

      # Delete a Question Group
      within 'li#question_group_1' do
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
      sleep 1
      expect(SurveyAssignment.count).to eq(1)

      click_link 'Create Notifications'
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
      sleep 1
      expect(SurveyAssignment.count).to eq(0)

      # Destroy a survey
      visit '/surveys/1/edit'
      page.accept_confirm do
        click_link 'Delete this survey'
      end
      sleep 1
      expect(Survey.count).to eq(0)
    end

    it 'can view survey results' do
      survey = create(:survey)
      survey_assignment = create(:survey_assignment, survey_id: survey.id)
      create(:survey_notification, survey_assignment_id: survey_assignment.id,
                                   courses_users_id: CoursesUsers.last.id)
      answer = create(:answer)
      survey.rapidfire_question_groups << answer.question.question_group
      answer.question.update(track_sentiment: true, answer_options: 'foo')
      answer.answer_group.update(user_id: instructor.id)
      visit '/surveys/results'
      visit '/survey/results/1'
      expect(page).to have_content 'Average Sentiment'
      click_link 'Download Survey Results CSV'
      click_link 'Download Results CSV'
    end
  end
end
