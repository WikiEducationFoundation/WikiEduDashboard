# frozen_string_literal: true

require 'rails_helper'

describe 'Surveys', type: :feature, js: true do
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
    before do
      @instructor = create(:user)
      @course = create(:course, title: 'My Active Course', slug: 'my_active/course')
      article = create(:article)
      create(:articles_course, article_id: article.id, course_id: @course.id)

      @courses_user = create(
        :courses_user,
        user_id: @instructor.id,
        course_id: @course.id,
        role: 1
      )

      @survey = create(
        :survey,
        name: 'Instructor Survey',
        intro: 'Welcome to survey',
        thanks: 'You made it!',
        open: true
      )

      question_group = create(:question_group, id: 1, name: 'Basic Questions')
      @survey.rapidfire_question_groups << question_group
      @survey.save!

      # Q1
      # Matrix question at the start
      create(:matrix_question, question_text: 'first line', question_group_id: question_group.id)
      create(:matrix_question, question_text: 'second line', question_group_id: question_group.id)
      create(:matrix_question, question_text: 'third line', question_group_id: question_group.id)

      # Q2
      q_checkbox = create(:q_checkbox, question_group_id: question_group.id, conditionals: '')

      # Q3
      q_radio = create(:q_radio, question_group_id: question_group.id,
                                 conditionals: "#{q_checkbox.id}|=|hindi|multi")
      q_radio.rules[:presence] = '0'
      q_radio.save!

      # Q4
      @q_long = create(:q_long, question_group_id: question_group.id)

      # Q5
      @q_select = create(:q_select, question_group_id: question_group.id)
      @q_select.rules[:presence] = '0'
      @q_select.follow_up_question_text = 'Anything else?'
      @q_select.save!

      # Q6
      q_select2 = create(:q_select, question_group_id: question_group.id)
      q_select2.rules[:presence] = '0'
      q_select2.multiple = true
      q_select2.save!

      # Q7
      @q_short = create(:q_short, question_group_id: question_group.id)
      @q_short.rules[:presence] = '0'
      @q_short.save!
      # Q8
      @q_numeric = create(:q_numeric, question_group_id: question_group.id)
      @q_numeric.rules[:maximum] = '500'
      @q_numeric.rules[:minimum] = '1'
      @q_numeric.save!

      create(:q_checkbox, question_group_id: question_group.id, answer_options: '',
                          course_data_type: 'Students')
      # Q9
      create(:q_checkbox, question_group_id: question_group.id, answer_options: '',
                          course_data_type: 'Articles')
      create(:q_checkbox, question_group_id: question_group.id, answer_options: '',
                          course_data_type: 'WikiEdu Staff')

      # Q10
      create(:q_rangeinput, question_group_id: question_group.id)

      # Q11 — this question will be removed because there are no WikiEdu staff
      # to select from for this course.
      q_select3 = create(:q_select, question_group_id: question_group.id,
                                    course_data_type: 'WikiEdu Staff')
      q_select3.rules[:presence] = '0'
      q_select3.answer_options = ''
      q_select3.save!

      # Q12 - this won't show up because the conditonal is not met
      q_text = create(:q_text, question_group_id: question_group.id,
                               conditionals: "#{q_checkbox.id}|=|telugu")
      q_text.rules[:presence] = '0'
      q_text.save!

      # Matrix questions back-to-back, and matrix question at the end of survey
      # Q13
      create(:matrix_question, question_text: 'first line', question_group_id: question_group.id)
      create(:matrix_question, question_text: 'second line', question_group_id: question_group.id)
      create(:matrix_question, question_text: 'third line', question_group_id: question_group.id)
      # Q14
      create(:matrix_question2, question_text: 'first line', question_group_id: question_group.id)
      create(:matrix_question2, question_text: 'second line', question_group_id: question_group.id)
      create(:matrix_question2, question_text: 'third line', question_group_id: question_group.id)

      survey_assignment = create(
        :survey_assignment,
        survey_id: @survey.id
      )
      create(:survey_notification,
             course_id: @course.id,
             survey_assignment_id: survey_assignment.id,
             courses_users_id: @courses_user.id)
    end

    it 'sets the course and shows the progress bar by going directly to the survey' do
      login_as(@instructor, scope: :user)
      visit survey_path(@survey)
      # Sets the course automatically
      expect(page).to have_content 'Survey for My Active Course'
      expect(page).to have_content 'progress'
    end

    it 'sets the course and shows the progress bar by going to the course page' do
      stub_token_request
      login_as(@instructor, scope: :user)

      visit "/courses/#{@course.slug}"
      expect(page).to have_content 'Take our survey for this course.'
      click_link 'Take Survey'
      # Sets the course automatically
      expect(page).to have_content 'Survey for My Active Course'
      expect(page).to have_content 'progress'
    end

    it 'renders an optout page' do
      login_as(@instructor, scope: :user)
      visit "#{survey_path(@survey)}/optout"
      expect(page).to have_content 'opted out'
    end

    it 'navigates correctly between each question and submits' do
      expect(Rapidfire::Answer.count).to eq(0)
      expect(SurveyNotification.last.completed).to eq(false)
      login_as(@instructor, scope: :user)
      visit survey_path(@survey)

      click_button('Start')

      sleep 1

      within('div[data-progress-index="2"]') do
        click_button('Next', visible: true) # Q1
      end

      sleep 1

      find('.label', text: 'hindi').click
      within('div[data-progress-index="3"]') do
        click_button('Next', visible: true) # Q2
      end

      sleep 1

      find('.label', text: 'female').click
      within('div[data-progress-index="4"]') do
        click_button('Next', visible: true) # Q3
      end

      sleep 1

      fill_in("answer_group_#{@q_long.id}_answer_text", with: 'testing')
      within('div[data-progress-index="5"]') do
        click_button('Next', visible: true) # Q4
      end

      sleep 1

      select('mac', from: "answer_group_#{@q_select.id}_answer_text")
      within('div[data-progress-index="6"]') do
        click_button('Next', visible: true) # Q5
      end

      sleep 1

      within('div[data-progress-index="7"]') do
        click_button('Next', visible: true) # Q6
      end

      sleep 1

      fill_in("answer_group_#{@q_short.id}_answer_text", with: 'testing')
      within('div[data-progress-index="8"]') do
        click_button('Next', visible: true) # Q7
      end

      sleep 1

      fill_in("answer_group_#{@q_numeric.id}_answer_text", with: '50')
      within('div[data-progress-index="9"]') do
        click_button('Next', visible: true) # Q8
      end

      sleep 1

      within('div[data-progress-index="10"]') do
        find('.label', text: 'None of the above').click
        click_button('Next', visible: true) # Q9
      end

      sleep 1

      within('div[data-progress-index="11"]') do
        click_button('Next', visible: true) # Q10
      end

      # Q11 not rendered
      # Q12 not rendered

      sleep 1

      within('div[data-progress-index="12"]') do
        click_button('Next', visible: true) # Q13
      end

      sleep 1

      # expect(page).not_to have_content 'You made it!'
      click_button('Submit Survey', visible: true) # Q14
      expect(page).to have_content 'You made it!'
      sleep 1
      expect(Rapidfire::Answer.count).to eq(22)
      expect(Rapidfire::AnswerGroup.last.course_id).to eq(@course.id)
      expect(SurveyNotification.last.completed).to eq(true)

      expect(Survey.last.to_csv).to match('username,') # beginning of header
      expect(Survey.last.to_csv).to match("#{@instructor.username},") # beginning of response row
    end

    it 'loads a question group preview' do
      visit '/surveys/rapidfire/question_groups/1/answer_groups/new?preview'
      visit '/surveys/rapidfire/question_groups/1/answer_groups/new?preview'\
            "&course_slug=#{Course.last.slug}"
    end
  end

  describe 'Permissions' do
    before do
      @user = create(:user)
      @admin = create(:admin)

      @instructor = create(:user, username: 'Professor Sage')
      course = create(:course)

      @courses_user = create(
        :courses_user,
        user_id: @instructor.id,
        course_id: course.id,
        role: 1
      )

      @open_survey = create(:survey, open: true)

      @survey = create(:survey)

      survey_assignment = create(
        :survey_assignment,
        courses_user_role: 1,
        survey_id: @survey.id
      )
      create(:survey_notification,
             course_id: course.id,
             survey_assignment_id: survey_assignment.id,
             courses_users_id: @courses_user.id)
    end

    it 'can view survey if the survey notification id is associated with current user' do
      login_as(@instructor, scope: :user)
      visit survey_path(@survey)
      expect(page).to have_current_path(survey_path(@survey))
    end

    it 'can view survey if it is open' do
      login_as(@user, scope: :user)
      visit survey_path(@open_survey)
      expect(page).to have_current_path(survey_path(@open_survey))
    end

    it 'can view survey if user is an admin' do
      login_as(@admin, scope: :user)
      visit survey_path(@survey)
      expect(page).to have_current_path(survey_path(@survey))
      login_as(@admin, scope: :user)
      visit survey_path(@open_survey)
      expect(page).to have_current_path(survey_path(@open_survey))
    end

    it 'redirects a user if not logged in or survey notification id isnt associated with them' do
      login_as(@user, scope: :user)
      visit survey_path(@survey)
      expect(page).to have_current_path(root_path)
    end
  end
end
