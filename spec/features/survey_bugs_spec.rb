# frozen_string_literal: true

require 'rails_helper'

describe 'Survey navigation and rendering', type: :feature, js: true do
  include Rapidfire::QuestionSpecHelper
  include Rapidfire::AnswerSpecHelper

  before do
    include type: :feature
    include Devise::TestHelpers
    page.current_window.resize_to(1920, 1080)
  end

  after do
    logout
  end

  describe 'Instructor takes survey' do
    let(:instructor) { create(:user) }
    let(:article) { create(:article) }
    let(:course) { create(:course) }

    before do
      login_as(instructor, scope: :user)

      create(:articles_course, article_id: article.id, course:)

      @courses_user = create(
        :courses_user,
        user: instructor,
        course:,
        role: 1
      )

      @survey = create(
        :survey,
        name: 'Instructor Survey',
        intro: 'Welcome to survey',
        thanks: 'You made it!',
        open: true
      )

      question_group = create(:question_group, name: 'Question group with conditionals')
      @survey.rapidfire_question_groups << question_group
      @survey.save!

      # Q1
      # Simple first question
      create(:q_checkbox, id: 1, question_group_id: question_group.id)

      # Q2
      # Question that determines whether to show next one
      create(:q_radio, id: 2, question_group_id: question_group.id,
                       question_text: 'Show the next question?',
                       answer_options: "Yes\r\nNo")

      # Q3
      # Question only show if previous question is answered Yes
      create(:q_radio, id: 3, question_group_id: question_group.id,
                       question_text: 'Should this be shown?',
                       answer_options: "Maybe\r\nPossibly",
                       conditionals: '2|=|Yes')

      # Q4
      # Last question
      create(:q_long, question_group_id: question_group.id)

      survey_assignment = create(
        :survey_assignment,
        survey_id: @survey.id
      )
      create(:survey_notification,
             course:,
             survey_assignment_id: survey_assignment.id,
             courses_users_id: @courses_user.id)
    end

    it 'handles changes in condition questions' do

      visit survey_path(@survey)

      click_button('Start')

      sleep 1

      find('.label', text: 'hindi').click
      within('div[data-progress-index="2"]') do
        click_button('Next', visible: true) # Q1
      end

      sleep 1

      # First select No. This means Q3 is skipped
      # and the last question is shown next.
      find('.label', text: 'No').click
      within('div[data-progress-index="3"]') do
        click_button('Next', visible: true) # Q2
      end

      expect(page).to have_content('Submit Survey')
      # Now go back to the previous question
      within('div[data-progress-index="4"]') do
        click_button('Previous', visible: true) # Q4
      end

      # Now change answer to yes, which inserts
      # Q3 into the flow.
      find('.label', text: 'Yes').click
      within('div[data-progress-index="3"]') do
        click_button('Next', visible: true) # Q2
      end

      sleep 1
      # Now go back to the previous question
      within('div[data-progress-index="4"]') do
        click_button('Previous', visible: true) # Q3
      end

      sleep 1

      # Change the answer again and proceed
      find('.label', text: 'No').click
      within('div[data-progress-index="3"]') do
        click_button('Next', visible: true) # Q2
      end

      # Now we can actually submit the survey
      # and finish.
      expect(page).to have_field("answer_group_#{Rapidfire::Question.last.id}_answer_text")
      fill_in("answer_group_#{Rapidfire::Question.last.id}_answer_text", with: 'Done!')
      expect(page).to have_content('Submit Survey')
      click_button('Submit Survey', visible: true)
      expect(page).to have_content 'You made it!'

    end
  end
end
