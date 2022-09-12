# frozen_string_literal: true

require 'rails_helper'

describe 'Survey notifications', type: :feature, js: true do
  let(:course) { create(:course) }
  let(:instructor) { create(:user) }
  let(:survey) { create(:survey) }
  let(:survey_assignment) { create(:survey_assignment, survey:) }

  before do
    # Make sure CSRF handling is configured properly so that
    # the survey_notification update trigger at the end of
    # surveys works properly.
    ActionController::Base.allow_forgery_protection = true

    course.campaigns << Campaign.first
    JoinCourse.new(course:, user: instructor, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)

    question_group = create(:question_group, name: 'Basic Questions')
    survey.rapidfire_question_groups << question_group
    create(:q_checkbox, question_group_id: question_group.id, conditionals: '')
    create(:survey_notification, survey_assignment:,
                                 courses_users_id: instructor.courses_users.first.id,
                                 course:)
    login_as(instructor)
    stub_token_request
  end

  after do
    ActionController::Base.allow_forgery_protection = false
  end

  it 'can be dismissed from the course page' do
    visit "/courses/#{course.slug}"
    expect(page).to have_content('Take our survey')
    accept_confirm do
      click_button 'Dismiss'
    end
    expect(page).not_to have_content('Take our survey')
  end

  it 'is marked complete after taking the survey' do
    visit "/courses/#{course.slug}"
    expect(page).to have_content('Take our survey')
    click_link 'Take Survey'
    find('.label', text: 'hindi').click
    click_button 'Submit Survey'
    expect(page).to have_content 'Thank You!'
    sleep 1
    visit "/courses/#{course.slug}"
    expect(page).not_to have_content('Take our survey')
    expect(SurveyNotification.last.completed).to be true
  end
end
