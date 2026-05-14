# frozen_string_literal: true

# Manual-only: captures before/after screenshots of pages we're auditing
# for accessibility. Run with:
#   SCREENSHOT_SUFFIX=before bundle exec rspec spec/features/a11y_screenshots.rb --tag screenshots
#   # ...make changes, yarn build...
#   SCREENSHOT_SUFFIX=after bundle exec rspec spec/features/a11y_screenshots.rb --tag screenshots
#
# Each example sets up minimal fixtures for its target page and saves a
# screenshot to tmp/screenshots/<page>_<suffix>.png.

require 'rails_helper'

describe 'accessibility screenshots', type: :feature, js: true, screenshots: true do
  # Use a separate directory so capybara-screenshot's prune-per-run
  # strategy (which empties tmp/screenshots/ on every spec run) doesn't
  # delete the before screenshots between runs.
  let(:screenshot_dir) { Rails.root.join('tmp', 'a11y_screenshots') }
  let(:suffix) { ENV['SCREENSHOT_SUFFIX'] || 'now' }

  before do
    FileUtils.mkdir_p(screenshot_dir)
    page.current_window.resize_to(1440, 1000)
  end

  describe 'admin dashboard' do
    let(:admin) { create(:admin) }
    let(:instructor) { create(:user, username: 'Professor Sage') }
    let!(:submitted_course) do
      create(:course, title: 'My Submitted Course', school: 'University',
                      term: 'Term', slug: 'University/Course_(Term)', submitted: true,
                      passcode: 'passcode', start: '2015-01-01'.to_date,
                      end: '2025-01-01'.to_date)
    end
    let!(:courses_user) do
      create(:courses_user, user: instructor, course: submitted_course,
                            role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end
    let!(:fall_campaign) { create(:campaign, title: 'Fall 2015') }
    let!(:spring_campaign) { create(:campaign, title: 'Spring 2016') }

    before { login_as(admin) }

    it 'snapshot' do
      visit root_path
      expect(page).to have_content 'Submitted & Pending Approval'
      sleep 1
      page.save_screenshot(screenshot_dir.join("admin_dashboard_#{suffix}.png"))
    end
  end

  describe 'tickets dashboard' do
    let(:admin) { create(:admin, email: 'spec@wikiedu.org') }
    let(:course) do
      create(:course, slug: 'NASA_School/Fly_me_to_the_moon',
                      title: 'Fly me to the moon')
    end
    let(:user) { create(:user, username: 'arogers', email: 'aron@packers.nfl.org') }

    before do
      TicketDispenser::Dispenser.call(
        content: 'I do not test content', owner_id: admin.id, sender_id: user.id,
        project_id: course.id, details: { subject: 'A first subject' }
      )
      create(:courses_user, course:, user:, role: CoursesUsers::Roles::STUDENT_ROLE)
      login_as admin
    end

    it 'snapshot' do
      visit '/tickets/dashboard'
      expect(page).to have_field 'tickets_search_email_or_username'
      sleep 1
      page.save_screenshot(screenshot_dir.join("tickets_dashboard_#{suffix}.png"))
    end
  end

  describe 'course timeline' do
    let(:start_date) { '2025-02-10'.to_date }
    let(:course) do
      create(:course, start: start_date, end: start_date + 2.months,
                      timeline_start: start_date, timeline_end: start_date + 2.months,
                      weekdays: '0101010', submitted: true)
    end
    let!(:week) { create(:week, course:) }
    let!(:block1) do
      create(:block, week:, id: 1, kind: Block::KINDS['assignment'],
                     title: 'Block Title', training_module_ids: [1], order: 0, points: 50)
    end
    let!(:block2) do
      create(:block, week:, id: 2, kind: Block::KINDS['in_class'],
                     title: 'Another Title', training_module_ids: [2], order: 1)
    end
    let!(:block3) do
      create(:block, week:, id: 3, kind: Block::KINDS['milestone'],
                     title: 'Third Title', training_module_ids: [3], points: 7, order: 2)
    end

    before { TrainingModule.load_all; login_as(create(:admin)); stub_oauth_edit }

    it 'snapshot' do
      visit "/courses/#{course.slug}/timeline"
      expect(page).to have_content 'Block Title'
      sleep 1
      page.save_screenshot(screenshot_dir.join("course_timeline_#{suffix}.png"))
    end
  end
end
