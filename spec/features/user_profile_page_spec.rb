# frozen_string_literal: true

require 'rails_helper'

describe 'user profile pages', type: :feature, js: true do
  let(:user) { create(:user, username: 'Sage') }
  let(:course) { create(:course) }
  let(:course2) { create(:course, slug: 'course/2') }
  let(:article) { create(:article) }
  let!(:revision) { create(:revision, date: course.start + 1.hour, user: user, article: article) }
  before do
    create(:courses_user, user: user, course: course, role: CoursesUsers::Roles::STUDENT_ROLE)
    create(:courses_user, user: user, course: course2, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    create(:articles_course, course: course, article: article)
  end
  it 'shows contribution statistics' do
    visit "/users/#{user.username}"
    expect(page).to have_content 'Total impact made by Sage as an instructor'
    expect(page).to have_content "Total impact made by Sage's students"
    expect(page).to have_content 'Total impact made by Sage as a student'
  end
end
