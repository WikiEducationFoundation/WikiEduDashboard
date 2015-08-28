require 'rails_helper'

def go_through_course_dates_and_timeline_dates
  first('attr[title="Wednesday"]').click
  within('.wizard__panel.active') do
    expect(page).to have_css('button.dark[disabled=""]')
  end
  first('.wizard__form.course-dates input[type=checkbox]').set(true)
  within('.wizard__panel.active') do
    expect(page).not_to have_css('button.dark[disabled=disabled]')
  end
  first('button.dark').click
  sleep 1
end

def go_through_researchwrite_wizard
  go_through_course_dates_and_timeline_dates

  # Advance past the timeline date panel
  first('button.dark').click
  sleep 1

  # Choose researchwrite option
  first('.wizard__option').first('button').click
  first('button.dark').click
  sleep 1

  # Click through the offered choices
  first('.wizard__option').first('button').click # Training not graded
  first('button.dark').click # Next
  sleep 1

  first('button.dark').click # Next (default getting started options)
  sleep 1

  first('.wizard__option').first('button').click # Instructor prepares list
  first('button.dark').click # Next
  sleep 1

  first('.wizard__option').first('button').click # Traditional outline
  first('button.dark').click # Next
  sleep 1

  first('.wizard__option').first('button').click # Yes, medical articles
  first('button.dark').click # Next
  sleep 1

  first('.wizard__option').first('button').click # Work live from start
  first('button.dark').click # Next
  sleep 1

  first('button.dark').click # Next (default 2 peer reviews)
  sleep 1

  first('button.dark').click # Next (no supplementary assignments)
  sleep 1

  first('button.dark').click # Next (no DYK/GA)
  sleep 1

  first('button.dark').click # Submit
  sleep 1
end

describe 'New course creation and editing', type: :feature do
  before do
    include Devise::TestHelpers, type: :feature
    Capybara.current_driver = :selenium
  end

  before :each do
    if page.driver.is_a?(Capybara::Webkit::Driver)
      page.driver.allow_url 'fonts.googleapis.com'
      page.driver.allow_url 'maxcdn.bootstrapcdn.com'
      page.driver.allow_url 'cdn.ravenjs.com'
      # page.driver.block_unknown_urls  # suppress warnings
    end
    create(:cohort)
    user = create(:user,
                  id: 1)
    login_as(user, scope: :user)
    visit root_path
  end

  describe 'course workflow', js: true do
    let(:instructor_name)  { 'Mr. Capybara' }
    let(:instructor_email) { 'capybara@wikiedu.org' }
    it 'should allow the user to create a course' do
      stub_oauth_edit

      find("a[href='/course_creator']").click
      expect(page).to have_content 'Create a New Course'
      find('#course_title').set('My awesome new course - Foo 101')

      # If we click before filling out all require fields, only the invalid
      # fields get restyled to indicate the problem.
      find('button.dark').click
      expect(find('#course_title')['class']).not_to include('invalid title')
      expect(find('#course_school')['class']).to include('invalid school')
      expect(find('#course_term')['class']).to include('invalid term')

      # Now we fill out all the fields and continue.
      find('#instructor_name').set(instructor_name)
      find('#instructor_email').set(instructor_email)
      find('#course_school').set('University of Wikipedia, East Campus')
      find('#course_term').set('Fall 2015')
      find('#course_subject').set('Advanced Studies')
      find('#course_expected_students').set('500')
      find('textarea').set('In this course, we study things.')

      # TODO: test the date picker instead of just setting fields
      start_date = '2015-01-01'
      end_date = '2015-12-15'
      find('input[placeholder="Start date (YYYY-MM-DD)"]').set(start_date)
      find('input[placeholder="End date (YYYY-MM-DD)"]').set(end_date)
      sleep 1

      # This click should create the course and start the wizard
      find('button.dark').click

      # Go through the wizard, checking necessary options.

      # This is the course dates screen
      sleep 3
      # validate either blackout date chosen
      # or "no blackout dates" checkbox checked
      expect(page).to have_css('button.dark[disabled=""]')
      start_input = first('input.start').value
      expect(start_input).to eq(start_date)

      # capybara doesn't like trying to click the calendar
      # to set a blackout date
      go_through_course_dates_and_timeline_dates
      sleep 1

      # This is the timeline datepicker
      find('input.timeline_start').set(start_date)
      find('input.timeline_end').set(end_date)
      first('button.dark').click

      sleep 1

      # This is the assignment type chooser

      # pick and choose
      page.all('.wizard__option')[1].first('button').click
      sleep 1
      first('button.dark').click
      sleep 1
      # pick 2 types of assignemnts
      page.all('div.wizard__option__checkbox')[1].click
      page.all('div.wizard__option__checkbox')[3].click
      sleep 1
      first('button.dark').click

      # on the summary
      sleep 1
      # go back to the pick and choose and choose different assignemtns
      page.all('button.wizard__option.summary')[3].click
      sleep 1
      page.all('div.wizard__option__checkbox')[3].click
      page.all('div.wizard__option__checkbox')[2].click
      page.all('div.wizard__option__checkbox')[4].click
      sleep 1
      first('button.dark').click
      sleep 1
      first('button.dark').click

      # Now we're back at the timeline, having completed the wizard.
      sleep 1
      expect(page).to have_content 'Week 1'
      expect(page).to have_content 'Week 2'

      # Click edit and then cancel
      first('button.dark').click
      sleep 1
      first('button').click

      # Click edit and then make a change and save it.
      sleep 1
      first('button.dark').click
      first('input').set('The first week')
      sleep 1
      first('input[type=checkbox]').set(true)
      sleep 1
      first('button.dark').click
      sleep 1
      expect(page).to have_content 'The first week'

      # Click edit, delete some stuff, and save it.
      first('button.dark').click
      sleep 1
      page.all('button.danger')[1].click
      sleep 1
      page.all('button.danger')[0].click
      sleep 1
      page.all('button.danger')[1].click
      sleep 1
      first('button.dark').click
      sleep 1
      expect(page).not_to have_content 'The first week'

      # Click edit, mark a gradeable and save it.
      first('button.dark').click
      sleep 1
      first('input[type=checkbox]').set(true)
      sleep 1
      first('button.dark').click
      sleep 1

      # Edit the gradeable.
      page.all('button').last.click
      sleep 1
      page.all('input').last.set('50')
      sleep 1
      page.all('button.dark').last.click
      sleep 1
      expect(page).to have_content 'Value: 50%'

      # Navigate back to overview, check relevant data, then delete course
      find('#overview-link').find('a').click

      within('.sidebar') do
        expect(page).to have_content I18n.t('courses.instructor.other')
        expect(page).to have_content instructor_name
        expect(page).to have_content instructor_email
      end

      sleep 1
      first('button.danger').click

      # Follow the alert popup instructions to complete the deletion
      prompt = page.driver.browser.switch_to.alert
      prompt.send_keys('My awesome new course - Foo 101')
      sleep 1
      prompt.accept
      expect(page).to have_content 'You are not participating in any courses'
    end

    it 'should not allow a second course with the same slug' do
      create(:course,
             id: 10001,
             title: 'Course',
             school: 'University',
             term: 'Term',
             slug: 'University/Course_(Term)',
             submitted: 0,
             listed: true,
             passcode: 'passcode',
             start: '2015-08-24'.to_date,
             end: '2015-12-15'.to_date,
             timeline_start: '2015-08-31'.to_date,
             timeline_end: '2015-12-15'.to_date)
      stub_oauth_edit

      find("a[href='/course_creator']").click
      expect(page).to have_content 'Create a New Course'
      find('#course_title').set('Course')
      find('#instructor_name').set(instructor_name)
      find('#instructor_email').set(instructor_email)
      find('#course_school').set('University')
      find('#course_term').set('Term')
      find('#course_subject').set('Advanced Studies')

      start_date = '2015-01-01'
      end_date = '2015-12-15'
      find('input[placeholder="Start date (YYYY-MM-DD)"]').set(start_date)
      find('input[placeholder="End date (YYYY-MM-DD)"]').set(end_date)
      sleep 1

      # This click should not successfully create a course.
      find('button.dark').click
      expect(page).to have_content 'This course already exists'
      expect(Course.all.count).to eq(1)
    end

    it 'should create a full-length research-write assignment' do
      create(:course,
             id: 10001,
             title: 'Course',
             school: 'University',
             term: 'Term',
             slug: 'University/Course_(Term)',
             submitted: 0,
             listed: true,
             passcode: 'passcode',
             start: '2015-08-24'.to_date,
             end: '2015-12-15'.to_date,
             timeline_start: '2015-08-31'.to_date,
             timeline_end: '2015-12-15'.to_date)
      create(:courses_user,
             user_id: 1,
             course_id: 10001,
             role: 1)
      stub_oauth_edit

      # Visit timline and open wizard
      visit "/courses/#{Course.first.slug}/timeline"
      wizard_link = "/courses/#{Course.first.slug}/timeline/wizard"
      find("a[href='#{wizard_link}']").click
      sleep 1

      go_through_researchwrite_wizard

      expect(page).to have_content 'Week 14'

      # Now submit the course
      first('a.button').click
      prompt = page.driver.browser.switch_to.alert
      prompt.accept
      expect(page).to have_content 'Your course has been submitted.'

      Course.last.weeks.each_with_index do |week, i|
        expect(week.order).to eq(i + 1)
      end
    end

    it 'should squeeze assignments into the course dates' do
      create(:course,
             id: 10001,
             title: 'Course',
             school: 'University',
             term: 'Term',
             slug: 'University/Course_(Term)',
             submitted: 0,
             listed: true,
             passcode: 'passcode',
             start: '2015-09-01'.to_date,
             end: '2015-10-09'.to_date,
             timeline_start: '2015-08-31'.to_date, # covers six calendar weeks
             timeline_end: '2015-10-09'.to_date)
      create(:courses_user,
             user_id: 1,
             course_id: 10001,
             role: 1)
      stub_oauth_edit

      # Visit timline and open wizard
      visit "/courses/#{Course.first.slug}/timeline"
      wizard_link = "/courses/#{Course.first.slug}/timeline/wizard"
      find("a[href='#{wizard_link}']").click
      sleep 1

      go_through_researchwrite_wizard

      expect(page).to have_content 'Week 6'
      expect(page).not_to have_content 'Week 7'
    end
  end

  after do
    logout
    Capybara.use_default_driver
  end
end
