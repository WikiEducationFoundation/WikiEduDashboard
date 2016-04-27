require 'rails_helper'

describe 'Survey Administration', type: :feature, js: true do
  include Rapidfire::QuestionSpecHelper
  include Rapidfire::AnswerSpecHelper

  before do
    include Devise::TestHelpers, type: :feature
    Capybara.current_driver = :selenium
    page.current_window.resize_to(1920, 1080)
  end

  context 'an admin' do
    before do
      admin = create(:admin)
      login_as admin
    end

    before do
      course = create(:course)
      course.cohorts << Cohort.last
      instructor = create(:user, email: 'instructor@school.edu')
      course.courses_users << create(:courses_user, user_id: instructor.id, role: 1)
    end

    it 'can create a Surveys, Question Group, and Question' do
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
      within('div#question_group_cohort_ids_chosen') do
        find('input').set('Spring 2015')
        find('input').native.send_keys(:return)
      end
      page.find('input.button').click
      expect(Rapidfire::QuestionGroup.count).to eq(1)

      # Create a question
      expect(Rapidfire::Question.count).to eq(0)
      click_link 'Add Question'
      find('textarea#question_text').set('Who is awesome?')
      find('textarea#question_answer_options').set('Me!')
      page.find('input.button').click
      expect(Rapidfire::Question.count).to eq(1)

      # Clone a question
      click_link 'Clone'
      expect(Rapidfire::Question.count).to eq(2)
    end

    it 'can create a Survey Assignment' do
      create(:survey)
      expect(SurveyAssignment.count).to eq(0)
      visit '/surveys/assignments'
      click_link 'New Survey Assignment'

      within('div#survey_assignment_cohort_ids_chosen') do
        find('input').set('Spring 2015')
        find('input').native.send_keys(:return)
      end
      fill_in('survey_assignment_send_date_days', with: '7')
      check 'survey_assignment_published'
      page.find('input.button').click
      expect(SurveyAssignment.count).to eq(1)
    end

    it 'can view survey results' do
      visit '/surveys/results'
    end
  end
end
