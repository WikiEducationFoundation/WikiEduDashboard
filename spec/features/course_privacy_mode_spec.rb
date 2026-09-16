# frozen_string_literal: true

require 'rails_helper'

describe 'Course privacy mode', type: :feature, js: true do
  before do
    page.current_window.resize_to(1920, 1080)
    TrainingModule.load_all
    stub_oauth_edit
    stub_wiki_validation
  end

  after { logout }

  context 'on the Wiki Ed dashboard' do
    let(:instructor) { create(:user, permissions: User::Permissions::INSTRUCTOR) }

    before do
      create(:training_modules_users, user_id: instructor.id, training_module_id: 3,
                                      completed_at: Time.zone.now)
      allow_any_instance_of(User).to receive(:returning_instructor?).and_return(true)
      login_as(instructor, scope: :user)
      visit root_path
      click_link 'Create Course'
      expect(page).to have_content 'Create a New Course'
    end

    it 'creates an obfuscated course when the privacy checkbox is ticked' do
      find('#course_title').set('Introduction to Biology')
      find('#course_school').set('State University')
      find('#course_term').set('Fall 2026')
      # Before the box is ticked, the form previews the identifying URL.
      expect(page).to have_content 'State_University/Introduction_to_Biology_(Fall_2026)'
      find('#course_confidential').click
      expect(page).not_to have_content 'State_University/Introduction_to_Biology_(Fall_2026)'

      find('#course_subject').click
      within('#course_subject') { all('div', text: 'Chemistry')[2].click }
      find('#course_expected_students').set('20')
      find('#course_level').click
      within('#course_level') { all('div', text: 'Introductory')[2].click }
      find('#course_format').click
      within('#course_format') { all('div', text: 'In-person')[2].click }
      find('#course_description').set('In this course, we study things.')
      click_button 'Next'

      find('.course_start-datetime-control input').set('2026-09-01')
      find('div.DayPicker-Day--selected', text: '1').click
      find('.course_end-datetime-control input').set('2026-12-01')
      find('div.DayPicker-Day', text: '15').click
      sleep 1
      click_button 'Create my Course!'

      expect(page).to have_current_path(
        %r{/courses/Confidential/Course_1_\(Fall_2026\)/timeline/wizard}, wait: 10
      )
      course = Course.last
      expect(course).to be_confidential
      expect(course.title).to eq('Course 1')
      expect(course.school).to eq('Confidential')
      expect(course.confidential_course_detail.real_title).to eq('Introduction to Biology')
      expect(course.confidential_course_detail.real_school).to eq('State University')
    end
  end

  context 'on the Programs & Events Dashboard' do
    let(:user) { create(:user) }

    before do
      allow(Features).to receive(:open_course_creation?).and_return(true)
      allow(Features).to receive(:disable_wiki_output?).and_return(true)
      allow(Features).to receive(:default_course_type).and_return('BasicCourse')
      allow(Features).to receive(:default_course_string_prefix).and_return('courses_generic')
      allow(Features).to receive(:wiki_ed?).and_return(false)
      login_as(user)
    end

    it 'does not offer the privacy checkbox' do
      visit root_path
      click_link 'Create an Independent Program'
      find('.program-description', text: /Edit-A-Thon/).click
      expect(page).to have_field('Program title:')
      expect(page).to have_css('#course_private')
      expect(page).not_to have_css('#course_confidential')
    end
  end
end
