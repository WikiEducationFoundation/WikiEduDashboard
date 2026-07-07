# frozen_string_literal: true

require_relative 'spec_helper'

# Drives the same instructor-launch flow as `g2_instructor_launch_spec`,
# but pauses at named moments to save screenshots of the instructor's Canvas
# integration UX. Output goes to the harvest run directory
# (`tmp/canvas-ux-screenshots/instructor/`, override with CANVAS_SHOTS_DIR);
# `bin/harvest-canvas-screenshots` collects it into the review gallery.
#
# Re-run to refresh the screenshots when the UX changes:
#
#   bin/staging-feature-spec spec/staging/instructor_setup_screenshots_spec.rb
#
# Uses friendlier course names ("Demo School", "Wiki Editing Demo
# Course") than the G2 spec's timestamped placeholders so the screenshots
# read well as documentation. Provisioning + teardown happen per run; no
# state is left behind on staging.
describe 'Instructor setup illustrated guide', :staging do
  # A local (per-example) value rather than a top-level constant:
  # constants declared in a describe block leak into the shared
  # namespace and clobber each other across staging spec files (g2
  # declares its own REQUIRED_ENV), which prints "already initialized
  # constant" warnings on every run.
  let(:required_env) do
    %w[
      CANVAS_ADMIN_TOKEN CANVAS_TEST_ACCOUNT_ID
      CANVAS_TEST_INSTRUCTOR_USER_ID
      CANVAS_TEST_INSTRUCTOR_LOGIN CANVAS_TEST_INSTRUCTOR_PASSWORD
      WIKIPEDIA_TEST_INSTRUCTOR_USERNAME WIKIPEDIA_TEST_INSTRUCTOR_PASSWORD
      DASHBOARD_TEST_CAMPAIGN_SLUG
    ]
  end

  let(:run_id)             { Time.now.strftime('%Y%m%d%H%M%S') }
  let(:canvas_course_name) { 'Wiki Editing Demo Course' }
  let(:canvas_course_code) { 'WED-101' }
  let(:dashboard_title)    { 'Wiki Editing Demo' }
  let(:dashboard_school)   { 'Demo School' }
  let(:dashboard_term)     { "Demo #{run_id}" }
  let(:canvas_api)         { CanvasApiClient.new }
  let(:provisioned)        { @provisioned ||= {} }
  let(:screenshot_dir)     { canvas_shots_dir('instructor') }

  before do
    missing = required_env.select { |k| ENV[k].to_s.empty? }
    skip("missing env vars: #{missing.join(', ')}") if missing.any?

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
      # Settle the iframe (reload past any transient edge-500) so the shot
      # shows the real launch landing, not a momentary server error.
      settle_canvas_tool_iframe
      capture('02-canvas-iframe-landing')

      break_out_of_canvas_iframe(role: :instructor)
    end

    # New tab is now active; dashboard setup view rendered.
    sleep 1
    dismiss_consent_banner
    capture('03-dashboard-setup-empty')

    if page.has_select?('course_slug')
      # The option is labelled with the readable course title; its value is
      # still the slug, so pick it by value rather than the displayed text.
      slug = provisioned[:dashboard_course_slug]
      find("#course_slug option[value='#{slug}']").select_option
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

    # The LmsIntegrationStatus panel (StaffView) renders in the course
    # Home sidebar once the binding sets course.flags[:canvas_integration]:
    # the linked Canvas course, last sync, and synced-students count.
    await_lms_panel
    scroll_into_view('.lms-integration-status')
    capture('06-instructor-course-panel')
  end

  def capture(name)
    save_screenshot_to(screenshot_dir, name)
  end
end
