# frozen_string_literal: true

# Manual-only: zooms a sample of representative pages to 200% and pauses
# so a human can visually verify WCAG 2.1 1.4.4 Resize Text conformance.
#
# WCAG 1.4.4: "Except for captions and images of text, text can be resized
# without assistive technology up to 200 percent without loss of content or
# functionality."
#
# What to look for at 200% on each page:
#   - Any text clipped or hidden behind another element.
#   - Buttons or controls that become unclickable (off-screen, overlapped).
#   - Modal close buttons that scroll out of reach.
#   - Form fields where the label crashes into the input.
#   - Disappeared content that was visible at 100%.
# Horizontal scrolling at the page level is acceptable for 1.4.4
# (it's 1.4.10's problem, not this one).
#
# Run with:
#   HEADED=1 SLOW=1 OBSERVE=5 bundle exec rspec spec/features/resize_text_check.rb
#
# HEADED=1 is required so a browser opens. SLOW adds the existing per-action
# slow-mode pause. OBSERVE is the per-page observation pause in seconds
# (defaults to 5). Increase if you want longer to look. Screenshots of each
# zoomed page are saved to tmp/resize_text_screenshots/ for later review.

require 'rails_helper'

describe 'resize text 200% check', type: :feature, js: true, resize_text: true do
  let(:screenshot_dir) { Rails.root.join('tmp', 'resize_text_screenshots') }
  let(:observe_seconds) { (ENV['OBSERVE'] || '5').to_f }

  before do
    FileUtils.mkdir_p(screenshot_dir)
    page.current_window.resize_to(1440, 1000)
  end

  # Apply a 200% page zoom using the CSS `zoom` property. This is the closest
  # behaviour to a user pressing Ctrl/Cmd-+ twice in Chrome: layout reflows,
  # text and UI scale together. Then pause so the user can inspect.
  def zoom_to_200_and_observe(snapshot_name)
    page.execute_script("document.documentElement.style.zoom = '2';")
    sleep observe_seconds
    page.save_screenshot(screenshot_dir.join("#{snapshot_name}.png"))
  end

  describe 'logged-out home' do
    it 'snapshot' do
      visit root_path
      expect(page).to have_content I18n.t('application.log_in')
      zoom_to_200_and_observe('01_logged_out_home')
    end
  end

  describe 'explore page' do
    before do
      create(:campaign, title: 'Sample Campaign A',
                        start: Date.civil(2016, 1, 10),
                        end: Date.civil(2050, 2, 10))
      create(:course, title: 'A sample course',
                      slug: 'foo/sample_course',
                      start: Date.civil(2016, 1, 10),
                      end: Date.civil(2050, 1, 10))
    end

    it 'snapshot' do
      visit '/explore'
      expect(page).to have_content 'Sample Campaign A'
      zoom_to_200_and_observe('02_explore')
    end
  end

  describe 'course overview page' do
    let(:course) do
      create(:course, title: 'A sample course',
                      school: 'Sample University',
                      term: 'Spring 2025',
                      slug: 'Sample_University/A_sample_course_(Spring_2025)',
                      start: '2025-01-01'.to_date,
                      end: '2025-06-01'.to_date)
    end
    let(:instructor) { create(:user, username: 'Professor Sample') }

    before do
      create(:courses_user, user: instructor, course:,
                            role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      stub_token_request
      login_as instructor
    end

    it 'snapshot' do
      visit "/courses/#{course.slug}"
      expect(page).to have_content course.title
      zoom_to_200_and_observe('03_course_overview')
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
      create(:block, week:, id: 1001, kind: Block::KINDS['assignment'],
                     title: 'Sample assignment block', order: 0, points: 50)
    end
    let!(:block2) do
      create(:block, week:, id: 1002, kind: Block::KINDS['in_class'],
                     title: 'Sample in-class block', order: 1)
    end

    before do
      TrainingModule.load_all
      login_as create(:admin)
      stub_oauth_edit
    end

    it 'snapshot' do
      visit "/courses/#{course.slug}/timeline"
      expect(page).to have_content 'Sample assignment block'
      zoom_to_200_and_observe('04_course_timeline')
    end
  end

  describe 'course creation modal' do
    let(:instructor) do
      create(:user, id: 1, permissions: User::Permissions::INSTRUCTOR)
    end

    before do
      TrainingModule.load_all
      stub_oauth_edit
      create(:training_modules_users, user_id: instructor.id,
                                      training_module_id: 3,
                                      completed_at: Time.zone.now)
      login_as instructor, scope: :user
    end

    it 'snapshot' do
      visit root_path
      click_link 'Create Course'
      expect(page).to have_content 'Create a New Course'
      zoom_to_200_and_observe('05_course_creator_modal')
    end
  end

  describe 'survey admin' do
    let(:admin) { create(:admin) }

    before do
      create(:survey, name: 'Sample Survey')
      login_as admin
    end

    it 'snapshot' do
      visit '/surveys'
      expect(page).to have_content 'Sample Survey'
      zoom_to_200_and_observe('06_survey_admin')
    end
  end

  describe 'admin dashboard' do
    let(:admin) { create(:admin) }
    let(:instructor) { create(:user, username: 'Professor Sample') }
    let!(:submitted_course) do
      create(:course, title: 'A submitted course', school: 'Sample U',
                      term: 'Spring 2025',
                      slug: 'Sample_U/A_submitted_course_(Spring_2025)',
                      submitted: true,
                      start: '2025-01-01'.to_date, end: '2025-06-01'.to_date)
    end
    let!(:courses_user) do
      create(:courses_user, user: instructor, course: submitted_course,
                            role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end

    before { login_as admin }

    it 'snapshot' do
      visit root_path
      expect(page).to have_content 'Submitted & Pending Approval'
      zoom_to_200_and_observe('07_admin_dashboard')
    end
  end

  describe 'onboarding' do
    let(:user) { create(:user, onboarded: false, real_name: 'Sample', email: 'sample@example.com') }

    before do
      stub_list_users_query
      login_as user, scope: :user
    end

    it 'snapshot' do
      visit onboarding_path
      expect(page).to have_content 'excited'
      zoom_to_200_and_observe('08_onboarding')
    end
  end
end
