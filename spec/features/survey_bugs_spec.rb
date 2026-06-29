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
      pending 'This sometimes fails for unknown reasons.'

      visit survey_path(@survey)

      click_button('Start')

      # Q1: answer and proceed
      expect(page).to have_css('.label', text: 'hindi')
      find('.label', text: 'hindi').click
      click_button('Next', visible: true)

      # Q2: select No first (Q3 is conditionally skipped)
      expect(page).to have_text('Show the next question?')
      find('.label', text: 'No').click
      click_button('Next', visible: true)

      # Q4 appears (Q3 was skipped)
      expect(page).to have_content('Submit Survey')

      # Go back to Q2
      click_button('Previous', visible: true)

      # Q2: change answer to Yes, which inserts Q3 into the flow
      expect(page).to have_text('Show the next question?')
      find('.label', text: 'Yes').click
      click_button('Next', visible: true)

      # Q3 now appears
      expect(page).to have_text('Should this be shown?')

      # Go back to Q2
      click_button('Previous', visible: true)

      # Q2: change answer back to No
      expect(page).to have_text('Show the next question?')
      find('.label', text: 'No').click
      click_button('Next', visible: true)

      # Q4 appears again (Q3 skipped again)
      expect(page).to have_content('Submit Survey')

      # Submit the survey
      fill_in("answer_group_#{Rapidfire::Question.last.id}_answer_text", with: 'Done!')
      click_button('Submit Survey', visible: true)
      expect(page).to have_content 'You made it!'

      pass_pending_spec
    end
  end
end
