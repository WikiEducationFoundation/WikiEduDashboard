# frozen_string_literal: true

require 'rails_helper'

describe 'AiEditAlert mailer previews', type: :feature, js: true do
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

  it 'renders exercise-specific instructor advice email' do
    visit preview_url('instructor_exercise_advice')
    expect(page).to have_content 'head off future copying-and-pasting'
  end

  it 'renders sandbox-specific instructor advice email' do
    visit preview_url('instructor_sandbox_advice')
    expect(page).to have_content 'none of this text was written by generative AI chatbots'
  end

  it 'renders mainspace-specific instructor advice email' do
    visit preview_url('instructor_mainspace_advice')
    expect(page).to have_content 'immediately revert'
  end
end
