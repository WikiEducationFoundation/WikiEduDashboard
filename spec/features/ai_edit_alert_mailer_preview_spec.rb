# frozen_string_literal: true

require 'rails_helper'

describe 'AiEditAlert mailer previews', type: :feature, js: true do
  # The mailer preview uses Course.last, FellowsCohort.last, and
  # User.where(permissions: 3).first — so we need these records to exist.
  # The admin must have an email so the mailer doesn't early-return when
  # building its recipient list.
  let(:admin) { create(:super_admin, email: 'admin@example.com') }
  let(:course) { create(:course) }
  let(:fellows_cohort) { create(:fellows_cohort) }
  let(:instructor) { create(:user, email: 'instructor@example.com') }

  before do
    admin
    # fellows_cohort first so Course.last is the ClassroomProgramCourse
    fellows_cohort
    course
    create(:courses_user, user: instructor, course: course,
           role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
  end

  def preview_url(name)
    "/rails/mailers/ai_edit_alert_mailer/#{name}?part=text%2Fhtml"
  end

  it 'renders student program alert for a mainspace article (default intro)' do
    visit preview_url('student_program_ai_edit_alert_mainspace')
    expect(page).to have_content 'added to Wikipedia in the course'
    expect(page).to have_content 'Artwork title'
    expect(page).to have_content 'Fully AI Generated'
  end

  it 'renders student program alert for an exercise page (:outline → exercise intro)' do
    visit preview_url('student_program_ai_edit_alert_exercise')
    expect(page).to have_content 'Heads up!'
    expect(page).to have_content 'added to Wikipedia as an exercise'
  end

  it 'renders student program alert for a sandbox/draft page (sandbox intro)' do
    visit preview_url('student_program_ai_edit_alert_sandbox_draft')
    expect(page).to have_content 'drafted for Wikipedia'
  end

  it 'renders scholars program alert (non-ClassroomProgramCourse → email template)' do
    visit preview_url('scholars_program_ai_edit_alert')
    expect(page).to have_content 'Help us understand how AI-generated text'
    expect(page).to have_content 'Fully AI Generated'
  end

  it 'renders instructor guidance email for first alert' do
    visit preview_url('instructor_guidance_for_first_alert')
    expect(page).to have_content "You've received a message with your student on copy"
  end
end
