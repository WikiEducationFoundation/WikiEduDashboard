# frozen_string_literal: true

require 'fileutils'
require_relative 'spec_helper'

# Drives the same instructor-launch flow as `g2_instructor_launch_spec`,
# but pauses at named moments to write screenshots into the tracked
# `.claude/canvas_integration/canvas_integration_instructor_guide/screenshots/`
# directory. Those screenshots back the illustrated guide of the same name.
#
# Re-run to refresh the guide when the UX changes:
#
#   bin/staging-feature-spec spec/staging/instructor_setup_screenshots_spec.rb
#
# Uses friendlier course names ("Demo School", "Wiki Editing Demo
# Course") than the G2 spec's timestamped placeholders so the screenshots
# read well as documentation. Provisioning + teardown happen per run; no
# state is left behind on staging.
describe 'Instructor setup illustrated guide', :staging do
  REQUIRED_ENV = %w[
    CANVAS_ADMIN_TOKEN CANVAS_TEST_ACCOUNT_ID
    CANVAS_TEST_INSTRUCTOR_USER_ID
    CANVAS_TEST_INSTRUCTOR_LOGIN CANVAS_TEST_INSTRUCTOR_PASSWORD
    WIKIPEDIA_TEST_INSTRUCTOR_USERNAME WIKIPEDIA_TEST_INSTRUCTOR_PASSWORD
    DASHBOARD_TEST_CAMPAIGN_SLUG
  ].freeze

  SCREENSHOT_DIR = Rails.root.join('.claude', 'canvas_integration',
                                   'canvas_integration_instructor_guide',
                                   'screenshots') if defined?(Rails)
  SCREENSHOT_DIR ||= File.expand_path(
    '../../.claude/canvas_integration/canvas_integration_instructor_guide/screenshots',
    __dir__
  )

  let(:run_id)             { Time.now.strftime('%Y%m%d%H%M%S') }
  let(:canvas_course_name) { 'Wiki Editing Demo Course' }
  let(:canvas_course_code) { 'WED-101' }
  let(:dashboard_title)    { 'Wiki Editing Demo' }
  let(:dashboard_school)   { 'Demo School' }
  let(:dashboard_term)     { "Demo #{run_id}" }
  let(:canvas_api)         { CanvasApiClient.new }
  let(:provisioned)        { @provisioned ||= {} }

  before do
    missing = REQUIRED_ENV.select { |k| ENV[k].to_s.empty? }
    skip("missing env vars: #{missing.join(', ')}") if missing.any?

    FileUtils.mkdir_p(SCREENSHOT_DIR)

    canvas_course = canvas_api.create_course(name: canvas_course_name,
                                             course_code: canvas_course_code)
    provisioned[:canvas_course_id] = canvas_course['id']
    canvas_api.enroll_user(course_id: canvas_course['id'],
                           user_id: ENV.fetch('CANVAS_TEST_INSTRUCTOR_USER_ID'),
                           role: 'TeacherEnrollment')
    dashboard_course = DashboardAdminClient.create_course(
      title: dashboard_title, school: dashboard_school, term: dashboard_term,
      instructor_username: ENV.fetch('WIKIPEDIA_TEST_INSTRUCTOR_USERNAME')
    )
    provisioned[:dashboard_course_slug] = dashboard_course['slug']
    DashboardAdminClient.approve_course(slug: dashboard_course['slug'],
                                        campaign_slug: ENV.fetch('DASHBOARD_TEST_CAMPAIGN_SLUG'))
  end

  after do
    if provisioned[:canvas_course_id]
      canvas_api.delete_course(course_id: provisioned[:canvas_course_id])
    end
    if provisioned[:dashboard_course_slug]
      DashboardAdminClient.delete_course(slug: provisioned[:dashboard_course_slug])
    end
  end

  it 'walks the instructor flow and captures a screenshot at each named step' do
    in_canvas do
      ensure_canvas_logged_in_as_instructor
      visit_canvas_course(provisioned[:canvas_course_id])
      capture('01-canvas-course-with-tab')

      click_wiki_education_tab
      # Let the iframe finish loading the dashboard landing page.
      sleep 2
      capture('02-canvas-iframe-landing')

      break_out_of_canvas_iframe(role: :instructor)
    end

    # New tab is now active; dashboard setup view rendered.
    sleep 1
    dismiss_consent_banner
    capture('03-dashboard-setup-empty')

    if page.has_select?('course_slug')
      select provisioned[:dashboard_course_slug], from: 'course_slug'
    else
      fill_in 'course_slug', with: provisioned[:dashboard_course_slug]
    end
    capture('04-dashboard-setup-course-selected')

    click_button 'Link this course'
    sleep 2
    capture('05-dashboard-course-bound')

    # Spaces in the slug come through URL-encoded in the browser bar.
    expect(CGI.unescape(page.current_url))
      .to include("/courses/#{provisioned[:dashboard_course_slug]}")
  end

  def capture(name)
    path = File.join(SCREENSHOT_DIR, "#{name}.png")
    page.save_screenshot(path)
    warn "  [guide screenshot] #{path}"
  end
end
