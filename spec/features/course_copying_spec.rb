# frozen_string_literal: true
require 'rails_helper'

describe 'course copying', type: :feature, js: true do
  let(:user) { create(:user) }
  let(:course_url) do
    'https://dashboard.wikiedu.org/courses/Riverside_City_College' \
      '/4A_Wikipedia_Assignment_(Spring_2024)'
  end

  before do
    allow(Features).to receive(:wiki_ed?).and_return(false)
    allow(Features).to receive(:open_course_creation?).and_return(true)
    stub_course
    stub_oauth_edit
    login_as(user, scope: :user)
  end

  let(:new_term) { 'Spring2016' }
  let(:subject) { 'Advanced Foo' }

  it 'checks copying of course across server' do
    visit root_path
    click_link 'Copy Course from another Server'
    fill_in 'url', with: course_url
    click_button 'Copy Course'

    within('.wizard__panel.active.cloned-course') do
      fill_in 'course_title', with: 'New Course Title'
      fill_in 'course_school', with: 'New School'
      fill_in 'course_description', with: 'New Course Description'
    end
    find('input#course_term').click
    fill_in 'course_term', with: new_term

    find('input#course_start').click
    find('div.DayPicker-Day', text: 13).click
    find('input#course_end').click
    find('div.DayPicker-Day', text: 28).click

    find('h3#clone_modal_header').click # This is just too close the datepicker
    click_button 'Save'
    expect(page).to have_current_path('/courses/New_School/New_Course_Title_(Spring2016)')

    new_course = Course.last
    expect(new_course.term).to eq('Spring2016')
    expect(new_course.weekdays).not_to eq('0000000')
    # expect(Week.count).to eq(1)
  end
end
