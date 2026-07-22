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
    # A realistic multi-week timeline so the import picker offers the full
    # assignment set (account + trainings + one per exercise).
    DashboardAdminClient.build_full_timeline(course_slug: dashboard_course['slug'])
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
    canvas_id = provisioned[:canvas_course_id]
    # Stage the realistic opt-in independent of the account tool's default:
    # start with the tab hidden (in the course's disabled nav items) so the
    # enabling step reads truthfully rather than already-on.
    canvas_api.set_course_nav(course_id: canvas_id, hidden: true)

    in_canvas do
      ensure_canvas_logged_in_as_instructor
      # The enabling step: the course's Navigation settings, with Wiki Education
      # Dashboard sitting in the disabled items lower in the list — scroll that
      # item into view (it's the only occurrence, since it's out of the nav now).
      visit "/courses/#{canvas_id}/settings#tab-navigation"
      item = find(:xpath, "//*[contains(text(), '#{tool_label}')]",
                  match: :first, wait: 20)
      page.execute_script('arguments[0].scrollIntoView({ block: "center" })', item)
      sleep 0.5
      capture('00-canvas-enable-nav')

      # Enable it (as the instructor would) so the rest of the flow launches.
      canvas_api.set_course_nav(course_id: canvas_id, hidden: false)
      visit_canvas_course(canvas_id)
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

    # The deep-link-first mode: nothing auto-created; assignments arrive via
    # the Modules-page import below. (The capture above shows the default
    # selection; the switch itself isn't part of the story.)
    find(:css, "input[type=radio][value='lumped']").click
    click_button 'Link this course'
    # Gate on the bound course home + its LMS panel rendering (which implies the
    # redirect finished) so the shot isn't a blank mid-load page, then clear the
    # fixed cookie-consent overlay before capturing.
    await_lms_panel
    dismiss_consent_banner
    capture('05-dashboard-course-bound')

    # Spaces in the slug come through URL-encoded in the browser bar.
    expect(CGI.unescape(page.current_url))
      .to include("/courses/#{provisioned[:dashboard_course_slug]}")

    # The LmsIntegrationStatus panel (StaffView) shows the linked Canvas course,
    # last sync, and synced-students count; scroll it into view.
    scroll_into_view('.lms-integration-status')
    capture('06-instructor-course-panel')

    capture_nav_status_and_import(canvas_id)
  end

  # Back in Canvas: the nav tab now renders the link-status view right in the
  # iframe, and the Modules-page placement imports every Wikipedia assignment
  # in one submit — the deep-link-first flow.
  def capture_nav_status_and_import(canvas_id)
    in_canvas do
      visit_canvas_course(canvas_id)
      click_wiki_education_tab
      # 'Students synced' is unique to the in-iframe status view (the landing
      # also mentions "Wiki Education Dashboard", so that text can't settle it).
      settle_in_iframe_view('Students synced', iframe: canvas_tool_iframe_locator)
      sleep 1
      capture('07-canvas-nav-status')

      import_assignments_via_modules(canvas_id,
                                     before_submit: -> { capture('08-import-picker') })
      sleep 1
      capture('09-module-created')

      visit "/courses/#{canvas_id}/assignments"
      expect(page).to have_content('Wikipedia account', wait: 20)
      sleep 1
      capture('10-assignments-index')
    end
  end

  def capture(name)
    save_screenshot_to(screenshot_dir, name)
  end
end
