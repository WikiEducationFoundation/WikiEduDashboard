# frozen_string_literal: true

require 'rails_helper'

# Admins write the course-creation deadline notice as HTML, and the course
# creator renders it unescaped for every instructor.
describe 'course creation notice', type: :feature, js: true do
  let(:user) { create(:user, permissions: User::Permissions::INSTRUCTOR) }

  before do
    TrainingModule.load_all
    create(:training_modules_users, user:, training_module_id: 3, completed_at: Time.zone.now)
    Deadlines.update_student_program(
      recruiting_term: 'fall_2026',
      deadline: 1.week.from_now.to_date,
      before_deadline_message: '<strong>One week left.</strong>' \
                               '<img src="x" onerror="window.noticeScriptRan = true">',
      after_deadline_message: 'Closed.'
    )
    login_as(user, scope: :user)
  end

  it 'keeps the formatting but drops script' do
    visit '/course_creator'
    expect(page).to have_css('.timeline-warning strong', text: 'One week left.')
    expect(page).not_to have_css('.timeline-warning img[onerror]')
    expect(page.evaluate_script('window.noticeScriptRan')).to be_nil
  end
end
