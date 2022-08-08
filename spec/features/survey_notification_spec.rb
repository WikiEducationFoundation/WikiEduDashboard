# frozen_string_literal: true

require 'rails_helper'

describe 'Survey notifications', type: :feature, js: true do
  let(:course) { create(:course) }
  let(:instructor) { create(:user) }
  let(:survey) { create(:survey) }
  let(:survey_assignment) { create(:survey_assignment, survey:) }

  before do
    course.campaigns << Campaign.first
    JoinCourse.new(course:, user: instructor, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)

    create(:survey_notification, survey_assignment:,
                                 courses_users_id: instructor.courses_users.first.id,
                                 course:)
    login_as(instructor)
    stub_token_request
  end

  it 'can be dismissed from the course page' do
    visit "/courses/#{course.slug}"
    expect(page).to have_content('Take our survey')
    accept_confirm do
      click_button 'Dismiss'
    end
    expect(page).not_to have_content('Take our survey')
  end
end
