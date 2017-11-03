# frozen_string_literal: true

require 'rails_helper'

def set_up_suite
  page.current_window.resize_to(1920, 1080)
  stub_oauth_edit
end

def fill_out_course_creator_form
  fill_in 'Course title:', with: 'My course'
  fill_in 'Course term:', with: 'Spring 2016'
  fill_in 'Course school:', with: 'University of Oklahoma'
  find('#course_expected_students').set('20')
  find('#course_description').set('My course at OU')
  find('.course_start-datetime-control input').set('2015-01-04')
  find('.course_end-datetime-control input').set('2015-02-01')
  find('div.wizard__panel').click # click to escape the calendar popup
  click_button 'Create my Course!'
end

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
  find('attr[title="Wednesday"]', match: :first).click
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

  find('.wizard__option', match: :first).find('button', match: :first).click # Biographies handout
  click_button 'Next'
  sleep 1

  click_button 'Next' # Default 2 peer reviews
  sleep 1

  click_button 'Next' # Default 3 discussions
  sleep 1

  click_button 'Next' # No supplementary assignments
  sleep 1

  click_button 'Next' # No DYK/GA
  sleep 1

  click_button 'Generate Timeline'
  sleep 1
end

describe 'New course creation and editing', type: :feature do
  before do
    set_up_suite
  end

  before :each do
    user = create(:user,
                  id: 1,
                  permissions: User::Permissions::INSTRUCTOR)
    create(:training_modules_users, user_id: user.id,
                                    training_module_id: 3,
                                    completed_at: Time.now)
    login_as(user, scope: :user)

    visit root_path
  end

  describe 'course workflow', js: true do
    let(:expected_course_blocks) { 23 }
    let(:module_name) { 'Get started on Wikipedia' }

    it 'should allow the user to create a course' do
      allow_any_instance_of(User).to receive(:returning_instructor?).and_return(true)
      click_link 'Create Course'

      expect(page).to have_content 'Create a New Course'
      find('#course_title').set('My awesome new course - Foo 101')

      # If we click before filling out all require fields, only the invalid
      # fields get restyled to indicate the problem.
      click_button 'Create my Course!'
      expect(find('#course_title')['class']).not_to include('invalid title')
      expect(find('#course_school')['class']).to include('invalid school')
      expect(find('#course_term')['class']).to include('invalid term')

      # Now we fill out all the fields and continue.
      find('#course_school').set('University of Wikipedia, East Campus')
      find('#course_term').set('Fall 2015')
      find('#course_subject').set('Advanced Studies')
      find('#course_expected_students').set('500')
      find('textarea').set('In this course, we study things.')

      sleep 1

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
      expect(start_input.to_date).to eq(start_date.to_date)
      end_input = find('input.end', match: :first).value
      expect(end_input.to_date).to eq(end_date.to_date)

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
      find('attr[title="Thursday"]', match: :first).click
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

      # Click edit, mark a gradeable and save it.
      find('.week-1').hover
      sleep 0.5
      within('.week-1') do
        omniclick all('.block__edit-block').first
        find('p.graded input[type=checkbox]').set(true)
        sleep 1
        click_button 'Save'
      end
      sleep 1

      # Edit the gradeable.
      within('.grading__grading-container') do
        click_button 'Edit'
        sleep 1
        all('input').last.set('50')
        sleep 1
        click_button 'Save'
        sleep 1
        expect(page).to have_content 'Value: 50%'
      end

      # Navigate back to overview, check relevant data, then delete course
      visit "/courses/#{Course.first.slug}"

      within('.sidebar') do
        expect(page).to have_content I18n.t('courses.instructor.other')
      end

      accept_prompt(with: 'My awesome new course - Foo 101') do
        find('button.danger', match: :first).click
      end

      expect(page).to have_content 'Looks like you don\'t have any courses'
    end

    it 'should not allow a second course with the same slug' do
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

      start_date = '2015-01-01'
      end_date = '2015-12-15'
      find('input[placeholder="Start date (YYYY-MM-DD)"]').set(start_date)
      find('input[placeholder="End date (YYYY-MM-DD)"]').set(end_date)
      find('div.wizard__panel').click # click to escape the calendar popup

      # This click should not successfully create a course.
      click_button 'Create my Course!'
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
      expect(page).to have_content 'Your course has been submitted.'

      Course.last.weeks.each_with_index do |week, i|
        expect(week.order).to eq(i + 1)
      end
      expect(Course.first.blocks.count).to eq(expected_course_blocks)
    end

    it 'should squeeze assignments into the course dates' do
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

      within ".week-1 .block-kind-#{Block::KINDS['assignment']}" do
        expect(page).to have_content module_name
      end
    end
  end

  describe 'returning instructor creating a new course', js: true do
    before do
      create(:course, id: 1)
      create(:courses_user,
             course_id: 1,
             user_id: 1,
             role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      create(:campaigns_course, course_id: 1, campaign_id: Campaign.first.id)
    end

    it 'should have the option of starting with no timeline' do
      visit root_path

      click_link 'Create Course'
      click_button 'Create New Course'
      fill_out_course_creator_form
      sleep 1
      go_through_course_dates_and_timeline_dates

      # Last option for returning instructor is 'build your own'
      find('button', text: 'Build your own timeline').click
      click_button 'Next'
      sleep 1

      # Proceed to the summary
      click_button 'Next'
      sleep 1

      # Finish the wizard
      click_button 'Generate Timeline'
      expect(page).to have_content 'Launch the Wizard' # 'no timeline' banner above the Timeline
      expect(page).to have_content 'Add Assignment' # Button in the Timeline
      sleep 1

      # Add a week
      within '.timeline__week-nav .panel' do
        find('.week-nav__add-week').click
      end
      sleep 1
      within '.timeline__weeks' do
        expect(page).to have_content 'Week 1'
        find('.week__add-block').click
        find('input.title').set('block title')
        within('.block__block-actions') do
          click_button 'Save'
        end
        sleep 1
      end
      # is it still there after reloading?
      visit current_path
      expect(page).to have_content 'Week 1'
      expect(page).to have_content 'block title'

      # Add Assignment button should not appear once there is timeline content.
      expect(page).not_to have_content 'Add Assignment'
    end
  end

  after do
    logout
  end
end

describe 'timeline editing', js: true do
  let(:course) do
    create(:course, id: 10001, start: Date.new(2015, 1, 1),
                    end: Date.new(2015, 2, 1), submitted: true,
                    timeline_start: Date.new(2015, 1, 1), timeline_end: Date.new(2015, 2, 1),
                    weekdays: '0111110')
  end
  let(:user) { create(:user, permissions: User::Permissions::ADMIN) }
  let!(:c_user) { create(:courses_user, course_id: course.id, user_id: user.id) }

  let(:week) { create(:week, course_id: course.id, order: 0) }
  let(:week2) { create(:week, course_id: course.id, order: 1) }

  before do
    set_up_suite
    login_as user, scope: :user, run_callbacks: false

    create(:block, week_id: week.id, kind: Block::KINDS['assignment'], order: 0, title: 'Block 1')
    create(:block, week_id: week.id, kind: Block::KINDS['in_class'], order: 1, title: 'Block 2')
    create(:block, week_id: week.id, kind: Block::KINDS['in_class'], order: 2, title: 'Block 3')
    create(:block, week_id: week2.id, kind: Block::KINDS['in_class'], order: 0, title: 'Block 4')
    create(:block, week_id: week2.id, kind: Block::KINDS['in_class'], order: 1, title: 'Block 5')
    create(:block, week_id: week2.id, kind: Block::KINDS['in_class'], order: 3, title: 'Block 6')
  end

  it 'disables reorder up/down buttons when it is the first or last block' do
    visit "/courses/#{Course.last.slug}/timeline"
    click_button 'Arrange Timeline'

    # Different Capybara drivers have slightly different behavior for disabled vs. not.
    truthy_values = [true, 'true']
    falsy_values = [nil, false, 'false']

    expect(falsy_values).to include(
      find('.week-1 .week__block-list > li:first-child button:first-of-type')['disabled']
    )
    expect(truthy_values).to include(
      find('.week-1 .week__block-list > li:first-child button:last-of-type')['disabled']
    )
    expect(truthy_values).to include(
      find('.week-2 .week__block-list > li:last-child button:first-of-type')['disabled']
    )
    expect(falsy_values).to include(
      find('.week-2 .week__block-list > li:last-child button:last-of-type')['disabled']
    )
  end

  it 'allows swapping places with a block' do
    visit "/courses/#{Course.last.slug}/timeline"
    click_button 'Arrange Timeline'
    # move down
    find('.week-1 .week__block-list > li:nth-child(1) button:first-of-type').trigger('click')
    sleep 0.5
    # move down again
    find('.week-1 .week__block-list > li:nth-child(2) button:first-of-type').trigger('click')
    sleep 0.5
    expect(find('.week-1 .week__block-list > li:nth-child(1)')).to have_content('Block 2')
    expect(find('.week-1 .week__block-list > li:nth-child(2)')).to have_content('Block 3')
    expect(find('.week-1 .week__block-list > li:nth-child(3)')).to have_content('Block 1')
    # move up
    find('.week-1 .week__block-list > li:nth-child(3) button:last-of-type').trigger('click')
    sleep 0.5
    # move up again
    find('.week-1 .week__block-list > li:nth-child(2) button:last-of-type').trigger('click')
    sleep 0.5
    expect(find('.week-1 .week__block-list > li:nth-child(1)')).to have_content('Block 1')
    expect(find('.week-1 .week__block-list > li:nth-child(2)')).to have_content('Block 2')
    expect(find('.week-1 .week__block-list > li:nth-child(3)')).to have_content('Block 3')
  end

  it 'allows moving blocks between weeks' do
    visit "/courses/#{Course.last.slug}/timeline"
    click_button 'Arrange Timeline'

    # move up to week 1
    find('.week-2 .week__block-list > li:nth-child(1) button:last-of-type').trigger('click')
    sleep 0.5
    expect(find('.week-1 .week__block-list > li:nth-child(4)')).to have_content 'Block 4'

    # move back down to week 2
    find('.week-1 .week__block-list > li:nth-child(4) button:first-of-type').trigger('click')
    sleep 0.5
    expect(find('.week-2 .week__block-list > li:nth-child(1)')).to have_content 'Block 4'
  end

  it 'allows user to save and discard changes' do
    visit "/courses/#{Course.last.slug}/timeline"
    click_button 'Arrange Timeline'

    # move up to week 1
    find('.week-2 .week__block-list > li:nth-child(1) button:last-of-type').trigger('click')
    click_button 'Save All'
    expect(find('.week-1 .week__block-list > li:nth-child(4)')).to have_content 'Block 4'

    # move down to week 2 and discard Changes
    click_button 'Arrange Timeline'
    find('.week-1 .week__block-list > li:nth-child(4) button:first-of-type').trigger('click')
    click_button 'Discard All Changes'
    # still in week 1
    expect(find('.week-1 .week__block-list > li:nth-child(4)')).to have_content 'Block 4'
  end
end
