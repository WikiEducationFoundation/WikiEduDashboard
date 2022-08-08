# frozen_string_literal: true

require 'rails_helper'

describe 'user profile pages', type: :feature, js: true do
  let(:user) { create(:user, username: 'Sage') }
  let(:course) { create(:course) }
  let(:course2) { create(:course, slug: 'course/2') }
  let(:article) { create(:article) }
  let!(:revision) { create(:revision, date: course.start + 1.hour, user:, article:) }

  before do
    create(:courses_user, user:, course:, role: CoursesUsers::Roles::STUDENT_ROLE)
    create(:courses_user, user:, course: course2, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    create(:articles_course, course:, article:)
  end

  it 'shows contribution statistics' do
    visit "/users/#{user.username}"
    expect(page).to have_content 'Total impact made by Sage as an instructor'
    expect(page).to have_content "Total impact made by Sage's students"
    expect(page).to have_content 'Total impact made by Sage as a student'
  end

  context 'when user has done training(s)' do
    before do
      TrainingModule.load
      create(:training_modules_users, user:, training_module_id: TrainingModule.first.id,
                                      completed_at: Time.zone.now)
    end

    it 'shows training status' do
      visit "/users/#{user.username}"
      expect(page).to have_content TrainingModule.first.name
      expect(page).to have_content 'Completed at'
    end
  end
end
