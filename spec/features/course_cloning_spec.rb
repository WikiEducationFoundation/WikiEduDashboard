# frozen_string_literal: true

require 'rails_helper'

describe 'cloning a course', js: true do
  before do
    stub_wiki_validation
    page.current_window.resize_to(1920, 1920)
    stub_oauth_edit
  end
  # This is super hacky to work around a combination of bugginess in the modal
  # and bugginess in the Capybara drivers. We want to avoid setting a date the
  # same as today's date.

  if (11..12).cover? Time.zone.today.day
    let(:course_start) { '13' }
    let(:timeline_start) { '14' }
  else
    let(:course_start) { '11' }
    let(:timeline_start) { '12' }
  end

  if (27..28).cover? Time.zone.today.day
    let(:course_end) { '26' }
    let(:timeline_end) { '25' }
  else
    let(:course_end) { '28' }
    let(:timeline_end) { '27' }
  end

  let!(:course) do
    create(:course, start: 1.year.from_now.to_date,
                    title: 'CourseToClone',
                    school: 'OriginalSchool',
                    term: 'OriginalTerm',
                    slug: 'OriginalSchool/CourseToClone_(OriginalTerm)',
                    subject: 'OrginalSubject',
                    end: 2.years.from_now.to_date, submitted: true,
                    expected_students: 0,
                    home_wiki_id: 3)
  end
  let!(:week) { create(:week, course_id: course.id) }
  let!(:block) { create(:block, week_id: week.id, due_date: course.start + 3.months, points: 15) }
  let!(:user) { create(:user, permissions: User::Permissions::ADMIN) }
  let!(:c_user) { create(:courses_user, course_id: course.id, user_id: user.id) }
  let(:new_term) { 'Spring2016' }
  let(:subject) { 'Advanced Foo' }
  let!(:tag) { create(:tag, tag: 'cloneable', course_id: course.id) }
  let!(:assignment) do
    create(:assignment, course_id: course.id, user_id: user.id, id: 123)
    create(:assignment, course_id: course.id, id: 12345)
  end

  # after do
  #   logout
  # end

  it 'copies relevant attributes of an existing course' do
    pending 'This sometimes fails for unknown reasons.'
    course.wikis = Wiki.find([1, 3, 4]) # Let the original course have some tracked wikis.
    login_as user, scope: :user, run_callbacks: false
    visit root_path
    click_link 'Create Course'
    click_button 'Clone Previous Course'
    select course.title, from: 'reuse-existing-course-select'
    click_button 'Clone This Course'

    expect(page).to have_content 'Update Details for Cloned Course'

    # interact_with_clone_form
    find('input#course_term').click
    fill_in 'course_term', with: 'OriginalTerm' # Same as original, not allowed
    fill_in 'course_subject', with: subject

    within '#details_column' do
      find('input#course_start').click
      find('div.DayPicker-Day', text: course_start).click
      find('input#course_end').click
      find('div.DayPicker-Day', text: course_end).click
      find('input#timeline_start').click
      find('div.DayPicker-Day', text: timeline_start).click
      find('input#timeline_end').click
      find('div.DayPicker-Day', text: timeline_end).click
    end

    find('h3#clone_modal_header').click # This is just too close the datepicker
    omniclick find('span', text: 'MO')
    omniclick find('span', text: 'WE')
    click_button 'Save New Course'
    expect(page).to have_content 'Mark the holidays' # Error message upon click.
    find('input#no_holidays').click
    expect(page).not_to have_content 'Mark the holidays'
    click_button 'Save New Course'

    # Fix the term to create an original slug, and try again
    expect(page).to have_content('This course already exists')
    fill_in 'course_term', with: new_term
    click_button 'Save New Course'

    expect(page).to have_current_path("/courses/OriginalSchool/CourseToClone_(#{new_term})")

    new_course = Course.last
    expect(new_course.term).to eq(new_term)
    expect(new_course.subject).to eq(subject)
    expect(new_course.weekdays).not_to eq('0000000')
    expect(Week.count).to eq(2) # make sure the weeks are distinct
    expect(new_course.blocks.first.content).to eq(course.blocks.first.content)
    expect(new_course.blocks.first.due_date)
      .to be_nil
    expect(new_course.blocks.first.points).to eq(15)
    expect(new_course.instructors.first).to eq(user)
    expect(new_course.submitted).to eq(false)
    expect(new_course.user_count).to be_zero
    expect(new_course.article_count).to be_zero
    expect(new_course.wikis.count).to eq(3) # Check if the tracked wikis are cloned.

    pass_pending_spec
  end

  it 'copies relevant attributes of an existing course with assignments' do
    course.wikis = Wiki.find([1, 3, 4]) # Let the original course have some tracked wikis.
    login_as user
    visit root_path
    click_link 'Create Course'
    click_button 'Clone Previous Course'
    select course.title, from: 'reuse-existing-course-select'
    find('input#copy_cloned_articles').click
    click_button 'Clone This Course'

    expect(page).to have_content 'Update Details for Cloned Course'

    # interact_with_clone_form
    find('input#course_term').click
    fill_in 'course_term', with: 'OriginalTerm' # Same as original, not allowed
    fill_in 'course_subject', with: subject

    within '#details_column' do
      find('input#course_start').click
      find('div.DayPicker-Day', text: course_start).click
      find('input#course_end').click
      find('div.DayPicker-Day', text: course_end).click
      find('input#timeline_start').click
      find('div.DayPicker-Day', text: timeline_start).click
      find('input#timeline_end').click
      find('div.DayPicker-Day', text: timeline_end).click
    end

    find('h3#clone_modal_header').click # This is just too close the datepicker
    omniclick find('span', text: 'MO')
    omniclick find('span', text: 'WE')
    click_button 'Save New Course'
    expect(page).to have_content 'Mark the holidays' # Error message upon click.
    find('input#no_holidays').click
    click_button 'Save New Course'

    # Fix the term to create an original slug, and try again
    expect(page).to have_content('This course already exists')
    fill_in 'course_term', with: new_term
    click_button 'Save New Course'

    expect(page).to have_current_path("/courses/OriginalSchool/CourseToClone_(#{new_term})")

    new_course = Course.last
    expect(new_course.term).to eq(new_term)
    expect(new_course.subject).to eq(subject)
    expect(new_course.weekdays).not_to eq('0000000')
    expect(Week.count).to eq(2) # make sure the weeks are distinct
    expect(new_course.blocks.first.content).to eq(course.blocks.first.content)
    expect(new_course.blocks.first.due_date)
      .to be_nil
    expect(new_course.blocks.first.points).to eq(15)
    expect(new_course.instructors.first).to eq(user)
    expect(new_course.submitted).to eq(false)
    expect(new_course.user_count).to be_zero
    expect(new_course.article_count).to be_zero
    expect(new_course.wikis.count).to eq(3) # Check if the tracked wikis are cloned.
    expect(new_course.assignments.count).to eq(1) # Making sure it copies assignment with no user
    expect(new_course.assignments.first.article_id).to eq(course.assignments.find(12345).article_id)
  end
end
