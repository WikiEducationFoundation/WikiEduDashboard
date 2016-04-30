require 'rails_helper'

describe 'Surveys', type: :feature, js: true do
  include Rapidfire::QuestionSpecHelper
  include Rapidfire::AnswerSpecHelper

  before do
    include Devise::TestHelpers, type: :feature
    Capybara.current_driver = :selenium
    page.current_window.resize_to(1920, 1080)
  end

  # describe 'The Survey index' do
  #   before :each do
  #     user = create(:admin,
  #                   id: 200,
  #                   wiki_token: 'foo',
  #                   wiki_secret: 'bar')
  #     login_as(user, scope: :user)
  #     visit '/surveys'
  #   end

    # it 'Lists all surveys and allows an admin to create a new one.' do
    #   click_link('New Survey')
    #   expect(page.find("h1")).to have_content("New Survey")
    #   fill_in('survey[name]', :with => 'My New Awesome Survey')
    #   click_button('Create Survey')
    #   expect(page.find(".course-list__row")).to have_content("My New Awesome Survey")
    #   click_link('Delete')
    #   prompt = page.driver.browser.switch_to.alert
    #   prompt.accept
    #   expect(page).not_to have_select('.course-list__row')
    # end

    # it 'Has a link to Question Groups' do
    #   click_link('Question Groups')
    #   expect(page).to have_content("Question Groups")
    # end
  # end

  describe 'Editing a Survey' do

    # let!(:question_group)  { FactoryGirl.create(:question_group, name: "Survey Section 1") }
    # let!(:survey)  { create(:survey, name: "Dumb Survey", :rapidfire_question_groups => [question_group]) }

    # before :each do
    #   create_questions(question_group)
    #   @intro_text = "My introduction"
    #   visit '/surveys'
    #   expect(page).to have_content(survey.name)
    #   within('.course-list__row') do
    #     find(:link, 'Edit').click
    #   end
    #   expect(page).to have_content("Editing #{survey.name}")
    # end

    # it 'An admin can the survey introduction' do
    #   fill_in_trix_editor("trix-toolbar-1", @intro_text)
    #   click_button "Update Survey";
    #   within('.course-list__row') do
    #     click_link("View Survey"); sleep 2;
    #     expect(page.find(".survey__title")).to have_content(survey.name)
    #     expect(page.find("[data-survey-block='0']")).to have_content(@intro_text)
    #   end
    # end
  end

  describe 'Permissions' do
    before(:each) do
      @user = create(:user)
      @admin = create(:admin,
                      id: 200,
                      wiki_token: 'foo',
                      wiki_secret: 'bar')

      @instructor = create(:user,
                           id: 100,
                           username: 'Professor Sage',
                           wiki_token: 'foo',
                           wiki_secret: 'bar')
      course = create(:course,
                      id: 10001,
                      title: 'My Active Course',
                      school: 'University',
                      term: 'Term',
                      slug: 'University/Course_(Term)',
                      submitted: 1,
                      listed: true,
                      passcode: 'passcode',
                      start: '2015-01-01'.to_date,
                      end: '2020-01-01'.to_date)

      @courses_user = create(
        :courses_user,
        id: 1,
        user_id: @instructor.id,
        course_id: 10001,
        role: 1)

      @open_survey = create(:survey, open: true)

      @survey = create(:survey)

      survey_assignment = create(
        :survey_assignment,
        courses_user_role: 1,
        survey_id: @survey.id)
      create(:survey_notification,
             course_id: course.id,
             survey_assignment_id: survey_assignment.id,
             courses_users_id: @courses_user.id)
    end

    it 'can view survey if the survey notification id is associated with current user' do
      login_as(@instructor, scope: :user)
      visit survey_path(@survey)
      expect(current_path).to eq(survey_path(@survey))
    end

    it 'can view survey if it is open' do
      login_as(@user, scope: :user)
      visit survey_path(@open_survey)
      expect(current_path).to eq(survey_path(@open_survey))
    end

    it 'can view survey if user is an admin' do
      login_as(@admin, scope: :user)
      visit survey_path(@survey)
      expect(current_path).to eq(survey_path(@survey))
      login_as(@admin, scope: :user)
      visit survey_path(@open_survey)
      expect(current_path).to eq(survey_path(@open_survey))
    end

    it 'redirects a user if not logged in or survey notification id isnt associated with them' do
      login_as(@user, scope: :user)
      visit survey_path(@survey)
      expect(current_path).to eq(root_path)
    end
  end

  describe 'Instructor takes survey' do
    before do
      @instructor = create(:user,
                           id: 100,
                           username: 'Professor Sage',
                           wiki_token: 'foo',
                           wiki_secret: 'bar')
      @courses_user = create(
        :courses_user,
        id: 1,
        user_id: @instructor.id,
        course_id: 10001,
        role: 1)

      @survey = create(
        :survey,
        name: 'Instructor Survey',
        intro: 'Welcome to survey',
        thanks: 'You made it!')

      course = create(:course,
                      id: 10001,
                      title: 'My Active Course',
                      school: 'University',
                      term: 'Term',
                      slug: 'University/Course_(Term)',
                      submitted: 1,
                      listed: true,
                      passcode: 'passcode',
                      start: (Time.zone.today - 2.weeks).to_date,
                      end: (Time.zone.today + 3.days).to_date)

      question_group = create(:question_group, name: 'Basic Questions')
      @survey.rapidfire_question_groups << question_group
      @survey.save
      create(:q_checkbox, question_group_id: question_group.id)
      q_long = create(:q_long, question_group_id: question_group.id)
      q_long.rules[:presence] = '0'
      q_long.save
      q_radio = create(:q_radio, question_group_id: question_group.id)
      q_radio.rules[:presence] = '0'
      q_radio.save
      q_select = create(:q_select, question_group_id: question_group.id)
      q_select.rules[:presence] = '0'
      q_select.save
      q_short = create(:q_short, question_group_id: question_group.id)
      q_short.rules[:presence] = '0'
      q_short.save
      create(:q_rangeinput, question_group_id: question_group.id)

      survey_assignment = create(
        :survey_assignment,
        survey_id: @survey.id)
      create(:survey_notification,
             course_id: course.id,
             survey_assignment_id: survey_assignment.id,
             courses_users_id: @courses_user.id)
    end

    it 'navigates correctly between each question and submits' do
      expect(Rapidfire::Answer.count).to eq(0)
      expect(SurveyNotification.last.completed).to eq(false)
      login_as(@instructor, scope: :user)
      visit survey_path(@survey)
      select('My Active Course', from: 'course_slug')
      click_button('Start Survey', visible: true)
      click_button('Start')

      find('.label', text: 'hindi').click
      sleep 1
      click_button('Next', visible: true)

      # FIXME: fails on travis, although it works locally.
      # fill_in('answer_group_2_answer_text', with: 'testing')
      sleep 1
      click_button('Next', visible: true)

      # FIXME: fails on travis, although it works locally.
      # find('.label', text: 'female').click
      sleep 1
      click_button('Next', visible: true)

      # FIXME: fails on travis, although it works locally.
      # select('mac', from: 'answer_group_4_answer_text')
      sleep 1
      click_button('Next', visible: true)

      # FIXME: fails on travis, although it works locally.
      # fill_in('answer_group_5_answer_text', with: 'testing')
      sleep 1
      click_button('Next', visible: true)
      expect(page).not_to have_content 'You made it!'
      click_button('Submit Survey', visible: true)
      expect(page).to have_content 'You made it!'
      expect(Rapidfire::Answer.count).to eq(6)
      expect(SurveyNotification.last.completed).to eq(true)
    end
  end

  after do
    logout
    Capybara.use_default_driver
  end
end
