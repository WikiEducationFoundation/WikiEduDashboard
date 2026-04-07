# frozen_string_literal: true

require 'rails_helper'

describe 'AI edit alert followup', type: :feature, js: true do
  let(:course) { create(:course) }
  let(:student) { create(:user, username: 'StudentUser') }
  let(:alert) do
    non_student_followup = { 'followup_AdminUser' => { response: 'I reviewed this' } }
    create(:ai_edit_alert, user: student, course: course,
           details: { article_title: 'History of Biology' }.merge(non_student_followup))
  end

  describe 'as the alert user' do
    before { login_as(student) }

    it 'shows the followup form and saves the response on submit' do
      visit "/alert_followup/#{alert.id}"
      expect(page).to have_content 'How did you use AI?'
      check 'I used an AI tool to generate text.'
      check 'ChatGPT'
      check 'to generate an initial draft'
      fill_in 'additional_context', with: 'I used it for drafting'
      click_button 'Submit'
      expect(page).to have_content 'Response saved. Thank you!'
      expect(alert.reload.details).to have_key("followup_#{student.username}")
    end
  end

  describe 'as an admin' do
    let(:admin) { create(:admin) }

    before { login_as(admin) }

    it 'can view the followup form' do
      visit "/alert_followup/#{alert.id}"
      expect(page).to have_content 'How did you use AI?'
    end

    it 'can view the alert in the alerts list' do
      visit "/alerts_list/#{alert.id}"
      expect(page).to have_content 'AiEditAlert'
      expect(page).to have_content 'History of Biology'
    end
  end

  describe 'as a course instructor' do
    let(:instructor) { create(:user) }

    before do
      create(:courses_user, user: instructor, course: course,
             role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      login_as(instructor)
    end

    it 'can view the followup form' do
      visit "/alert_followup/#{alert.id}"
      expect(page).to have_content 'How did you use AI?'
    end
  end

  describe 'as an unauthorized user' do
    let(:other_user) { create(:user) }

    before { login_as(other_user) }

    it 'renders an unauthorized response' do
      visit "/alert_followup/#{alert.id}"
      expect(page).to have_content 'not authorized'
    end
  end

  describe 'when not signed in' do
    it 'shows the sign-in prompt' do
      visit "/alert_followup/#{alert.id}"
      expect(page).to have_content 'Please sign in.'
    end
  end
end
