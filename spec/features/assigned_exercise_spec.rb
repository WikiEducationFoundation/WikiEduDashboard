# frozen_string_literal: true

require 'rails_helper'

describe 'students with assigned exercise modules', type: :feature, js: true do
  let(:student) { create(:user) }
  let(:course) { create(:course, weekdays: '1111111') }
  let(:week) { create(:week, course: course) }
  let(:evaluate_exercise_id) { 34 }
  let(:presentation_exercise_id) { 40 }
  let(:assigned_ids) { [evaluate_exercise_id] }

  before do
    ActionController::Base.allow_forgery_protection = true
    TrainingModule.load_all
    create(:block, week: week, training_module_ids: assigned_ids)
    course.campaigns << Campaign.first
    course.users << student
    create(:training_modules_users, user: student, training_module_id: evaluate_exercise_id,
                                    completed_at: Time.zone.now)
    login_as student
  end

  after do
    ActionController::Base.allow_forgery_protection = false
  end

  it 'can go mark a module complete, then mark it incomplete' do
    visit "/courses/#{course.slug}"

    expect(page).to have_content 'Upcoming Exercises'
    click_button 'Mark Complete'
    expect(page).not_to have_content 'Upcoming Exercises'
    click_link 'Resources'
    click_button 'Mark Incomplete'
    click_link 'Home'
    expect(page).to have_content 'Evaluate Wikipedia'
  end

  context 'when there are multiple incomplete exercises' do
    let(:assigned_ids) { [evaluate_exercise_id, presentation_exercise_id] }

    it 'see the next incomplete exercise after complete one' do
      visit "/courses/#{course.slug}"

      within '.my-exercises' do
        expect(page).to have_content 'Upcoming Exercises'
        expect(page).to have_content 'Evaluate Wikipedia'
        expect(page).not_to have_content 'In-class presentation'

        click_button 'Mark Complete'

        expect(page).to have_content 'Upcoming Exercises'
        expect(page).not_to have_content 'Evaluate Wikipedia'
        expect(page).to have_content 'In-class presentation'
      end
    end
  end
end
