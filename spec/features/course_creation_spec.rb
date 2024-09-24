# frozen_string_literal: true

require 'rails_helper'

def interact_with_clone_form
  fill_in 'Course term:', with: 'Spring 2016'
  fill_in 'Course description:', with: 'A new course'

  find('.course_start-datetime-control input').set(course.start)
  find('.course_end-datetime-control input').set(course.end)

  within('.wizard__form') { click_button 'Save New Course' }

  within('.sidebar') { expect(page).to have_content(term) }
  within('.primary') { expect(page).to have_content(desc) }

  click_button 'Save This Course'
end

def go_through_course_dates_and_timeline_dates
  find('span[title="Wednesday"]', match: :first).click
  within('.wizard__panel.active') do
    expect(page).to have_css('button.dark[disabled=""]')
  end
  find('.wizard__form.course-dates input[type=checkbox]', match: :first).set(true)
  within('.wizard__panel.active') do
    expect(page).not_to have_css('button.dark[disabled=disabled]')
  end

  click_button 'Next'
  sleep 1
end

def go_through_researchwrite_wizard
  go_through_course_dates_and_timeline_dates

  # Choose researchwrite option
  find('.wizard__option', match: :first).find('button', match: :first).click
  click_button 'Next'
  sleep 1

  # Click through the offered choices
  find('.wizard__option', match: :first).find('button', match: :first).click # Training not graded
  click_button 'Next'
  sleep 1

  click_button 'Next' # Default getting started options
  sleep 1

  click_button 'Next' # Default "Improving representation" option
  sleep 1

  # Working in groups
  find('.wizard__option', match: :first).find('button', match: :first).click
  click_button 'Next'
  sleep 1

  # Instructor prepares list
  find('.wizard__option', match: :first).find('button', match: :first).click
  click_button 'Next'
  sleep 1

  find('.wizard__option', match: :first).find('button', match: :first).click # Yes, medical articles
  click_button 'Next'
  sleep 1

  # Choose the first handout
  omniclick find('.wizard__option', match: :first).find('button', match: :first)
  click_button 'Next'
  sleep 1

  click_button 'Next' # Default 2 peer reviews
  sleep 1

  click_button 'Next' # Default 3 discussions
  sleep 1

  click_button 'Next' # No supplementary assignments except the default
  sleep 1

  # DYK/GA option removed for ~Spring 2021
  # click_button 'Next' # No DYK/GA
  # sleep 1

  ####################################
  # Fall 2020 supplemental questions #
  ####################################
  # contribute substantially
  omniclick find('.wizard__option', match: :first).find('button', match: :first)
  click_button 'Next'
  sleep 1
  # only assignment
  omniclick find('.wizard__option', match: :first).find('button', match: :first)
  click_button 'Next'
  sleep 1
  # # sandboxes unacceptable
  # omniclick find('.wizard__option', match: :first).find('button', match: :first)
  # click_button 'Next'
  sleep 1

  click_button 'Generate Timeline'
  sleep 1
end

describe 'New course creation and editing', type: :feature do
  before do
    page.current_window.resize_to(1920, 1080)
    TrainingModule.load_all
    stub_oauth_edit

    user = create(:user,
                  id: 1,
                  permissions: User::Permissions::INSTRUCTOR)
    create(:training_modules_users, user_id: user.id,
                                    training_module_id: 3,
                                    completed_at: Time.zone.now)
    login_as(user, scope: :user)

    visit root_path
  end

  after do
    logout
  end

  describe 'course workflow', js: true do
    let(:expected_course_blocks) { 26 }
    let(:module_name) { 'Get started on Wikipedia' }

    it 'allows the user to create a course' do
      allow_any_instance_of(User).to receive(:returning_instructor?).and_return(true)
      click_link 'Create Course'

      expect(page).to have_content 'Create a New Course'
      find('#course_title').set('My awesome new course - Foo 101')

      click_button 'Next'

      # If we click before filling out all require fields, only the invalid
      # fields get restyled to indicate the problem.
      expect(find('#course_title')['class']).not_to include('invalid title')
      expect(find('#course_school')['class']).to include('invalid school')
      expect(find('#course_term')['class']).to include('invalid term')

      # Now we fill out all the fields and continue.
      find('#course_school').set('University of Wikipedia, East Campus')
      find('#course_term').set('Fall 2015')

      find('#course_subject').click
      within '#course_subject' do
        all('div', text: 'Chemistry')[2].click
      end
      find('#course_expected_students').set('500')
      find('#course_level').click
      within '#course_level' do
        all('div', text: 'Introductory')[2].click
      end
      find('#course_format').click
      within '#course_format' do
        all('div', text: 'In-person')[2].click
      end
      find('#course_description').set('In this course, we study things.')
      click_button 'Next'

      start_date = '2015-01-01'
      end_date = '2015-12-15'
      find('.course_start-datetime-control input').set(start_date)
      find('div.DayPicker-Day--selected', text: '1').click
      find('.course_end-datetime-control input').set('2015-12-01')
      find('div.DayPicker-Day', text: '15').click

      sleep 1

      # This click should create the course and start the wizard
      click_button 'Create my Course!'

      # Go through the wizard, checking necessary options.

      # This is the course dates screen
      sleep 3
      # validate either blackout date chosen
      # or "no blackout dates" checkbox checked
      expect(page).to have_css('button.dark[disabled=""]')
      start_input = find('input.start', match: :first).value
      sleep 1
      expect(start_input.to_date).to be_within(1.day).of(start_date.to_date)
      end_input = find('input.end', match: :first).value
      expect(end_input.to_date).to be_within(1.day).of(end_date.to_date)

      # capybara doesn't like trying to click the calendar
      # to set a blackout date
      go_through_course_dates_and_timeline_dates

      # This is the assignment type chooser
      # Translation assignment
      page.all('.wizard__option')[2].first('button').click
      sleep 1
      click_button 'Next'
      sleep 1
      click_button 'Yes, training will be graded.'
      click_button 'Next'

      # Choosing articles
      sleep 1
      page.all('div.wizard__option')[0].click # Instructor prepares list
      click_button 'Next'

      # Optional assignment
      sleep 1
      click_button 'Do not include fact-checking assignment'
      click_button 'Next'

      # on the summary
      sleep 1
      # go back and change a choice
      page.all('button.wizard__option.summary')[2].click
      sleep 1
      click_button 'No, training will not be graded.'
      sleep 1
      click_button 'Summary'
      sleep 1
      click_button 'Generate Timeline'

      # Now we're back at the timeline, having completed the wizard.
      sleep 1
      expect(page).to have_content 'Week 1'
      expect(page).to have_content 'Week 2'

      # Edit course dates and save
      click_link 'Edit Course Dates'
      find('span[title="Thursday"]', match: :first).click
      click_link 'Done'
      sleep 1
      expect(Course.last.weekdays).to eq('0001100')

      within('.week-1 .week__week-add-delete') do
        accept_confirm do
          find('.week__delete-week').click
        end
      end

      # There should now be 4 weeks
      expect(page).not_to have_content 'Week 5'

      # Now check that the course form selections went through
      saved_course = Course.last
      expect(saved_course.level).to eq('Introductory')
      expect(saved_course.subject).to eq('Chemistry')
      expect(saved_course.format).to eq('In-person')
    end

    it 'does not allow a second course with the same slug' do
      create(:course,
             id: 10001,
             title: 'Course',
             school: 'University',
             term: 'Term',
             slug: 'University/Course_(Term)',
             submitted: false,
             passcode: 'passcode',
             start: '2015-08-24'.to_date,
             end: '2015-12-15'.to_date,
             timeline_start: '2015-08-31'.to_date,
             timeline_end: '2015-12-15'.to_date)

      click_link 'Create Course'
      expect(page).to have_content 'Create a New Course'
      find('#course_title').set('Course')
      find('#course_school').set('University')
      find('#course_term').set('Term')
      find('#course_subject').set('Advanced Studies')
      find('#course_expected_students').set('15')
      find('#course_description').set('My course')
      click_button 'Next'

      start_date = '2015-01-01'
      end_date = '2015-12-15'
      find('#course_start').set(start_date)
      find('#course_end').set(end_date)
      find('div.wizard__panel').click # click to escape the calendar popup

      # This click should not successfully create a course.
      click_button 'Create my Course!'
      expect(page).to have_content 'This course already exists'
      expect(Course.all.count).to eq(1)
    end

    it 'creates a full-length research-write assignment' do
      create(:course,
             id: 10001,
             title: 'Course',
             school: 'University',
             term: 'Term',
             slug: 'University/Course_(Term)',
             submitted: false,
             passcode: 'passcode',
             start: '2015-08-24'.to_date,
             end: '2015-12-15'.to_date,
             timeline_start: '2015-08-31'.to_date,
             timeline_end: '2015-12-15'.to_date)
      create(:courses_user,
             user_id: 1,
             course_id: 10001,
             role: 1)

      # Visit timline and open wizard
      visit "/courses/#{Course.first.slug}/timeline/wizard"
      sleep 1

      go_through_researchwrite_wizard

      sleep 1

      expect(page).to have_content 'Week 12'

      # Now submit the course
      accept_confirm do
        first('a.button').click
      end
      expect(page).to have_content 'Your course has been successfully submitted.'

      Course.last.weeks.each_with_index do |week, i|
        expect(week.order).to eq(i + 1)
      end
      expect(Course.first.blocks.count).to eq(expected_course_blocks)
    end

    it 'squeezes assignments into the course dates' do
      create(:course,
             id: 10001,
             title: 'Course',
             school: 'University',
             term: 'Term',
             slug: 'University/Course_(Term)',
             submitted: false,
             passcode: 'passcode',
             start: '2015-09-01'.to_date,
             end: '2015-10-09'.to_date,
             timeline_start: '2015-08-31'.to_date, # covers six calendar weeks
             timeline_end: '2015-10-09'.to_date)
      create(:courses_user,
             user_id: 1,
             course_id: 10001,
             role: 1)

      # Visit timline and open wizard
      visit "/courses/#{Course.first.slug}/timeline/wizard"
      sleep 1

      go_through_researchwrite_wizard

      expect(page).to have_content 'Week 6'
      expect(page).not_to have_content 'Week 7'
      expect(Course.first.blocks.count).to eq(expected_course_blocks)

      within '.week-1' do
        expect(page).to have_content module_name
      end
    end
  end
end
