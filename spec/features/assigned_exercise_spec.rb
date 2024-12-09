# frozen_string_literal: true

require 'rails_helper'

def stub_sandbox_existence_query(content)
  allow_any_instance_of(WikiApi).to receive(:get_page_content).and_return content
end

describe 'students with assigned exercise modules', type: :feature, js: true do
  let(:student) { create(:user) }
  let(:course) { create(:course, weekdays: '1111111') }
  let(:week) { create(:week, course:) }
  let(:evaluate_exercise_id) { 34 }
  let(:presentation_exercise_id) { 40 }
  let(:assigned_ids) { [evaluate_exercise_id] }

  before do
    ActionController::Base.allow_forgery_protection = true
    TrainingModule.load_all
    create(:block, week:, training_module_ids: assigned_ids)
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
    # Assume exercise sandbox has been created
    stub_sandbox_existence_query 'sandbox content'

    visit "/courses/#{course.slug}"

    expect(page).to have_content 'Upcoming Exercises'
    click_button 'Mark Complete'
    expect(page).not_to have_content 'Upcoming Exercises'
    click_link 'Resources'
    click_button 'Mark Incomplete'
    click_link 'Home'
    expect(page).to have_content 'Evaluate Wikipedia'
  end

  it 'see an error message if exercise sandbox does not exist' do
    stub_sandbox_existence_query ''

    visit "/courses/#{course.slug}"

    expect(page).to have_content 'Upcoming Exercises'
    click_button 'Mark Complete'
    expect(page).to have_content 'Please complete the exercise in your Exercise Sandbox'
  end

  context 'when there are multiple incomplete exercises' do
    let(:assigned_ids) { [evaluate_exercise_id, presentation_exercise_id] }

    it 'shows the next incomplete exercise after complete one' do
      # Assume exercise sandbox has been created
      stub_sandbox_existence_query 'sandbox content'

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

  context 'shows a link to the sandbox of an completed exercise' do
    let(:assigned_ids) { [evaluate_exercise_id] }

    it 'shows the next incomplete exercise after complete one' do
      # Assume exercise sandbox has been created
      stub_sandbox_existence_query 'sandbox content'

      visit "/courses/#{course.slug}"

      within '.my-exercises' do
        click_button 'Mark Complete'
      end

      expect(page).not_to have_content 'Evaluate Wikipedia'

      click_link 'Students'
      within '#users' do
        expect(page).to have_content student.username
        page.find('.name').click
      end

      within 'tr.students-exercise' do
        page.find('button').click
      end

      expect(page).to have_link 'Exercise Sandbox'
    end
  end
end
