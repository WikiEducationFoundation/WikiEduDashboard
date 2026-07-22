# frozen_string_literal: true

require_relative 'spec_helper'

# Captures the student-facing UX of the Canvas integration, surface by
# surface, into the harvest run directory
# (`tmp/canvas-ux-screenshots/student/`, override with CANVAS_SHOTS_DIR);
# `bin/harvest-canvas-screenshots` collects it into the review gallery.
# Re-run to refresh the images when the student flow changes:
#
#   bin/staging-feature-spec spec/staging/student_screenshots_spec.rb
#
# Three scenarios, each provisioning its own fresh Canvas + dashboard
# state and tearing it down afterward:
#   1. Happy path — in-iframe landing, post-OAuth enrollment landing, and
#      the student's LmsIntegrationStatus panel on the bound course.
#   2. Setup pending — the view a student hits when the instructor created
#      the binding but hasn't linked a Dashboard course yet.
#   3. Awaiting approval — the view a student hits when the bound course
#      isn't approved by Wiki Education staff yet.
#
# Two browser personas: the instructor sets up in the default profile,
# the student walks their flow in the student profile (`in_student_browser`).
# Both profiles must be bootstrapped once — see docs/staging_feature_specs.md.
describe 'Student UX screenshots', :staging do
  let(:required_env) do
    %w[
      CANVAS_ADMIN_TOKEN CANVAS_TEST_ACCOUNT_ID
      CANVAS_TEST_INSTRUCTOR_USER_ID
      CANVAS_TEST_INSTRUCTOR_LOGIN CANVAS_TEST_INSTRUCTOR_PASSWORD
      CANVAS_TEST_STUDENT_USER_ID
      CANVAS_TEST_STUDENT_LOGIN CANVAS_TEST_STUDENT_PASSWORD
      WIKIPEDIA_TEST_INSTRUCTOR_USERNAME WIKIPEDIA_TEST_INSTRUCTOR_PASSWORD
      WIKIPEDIA_TEST_STUDENT_USERNAME WIKIPEDIA_TEST_STUDENT_PASSWORD
      DASHBOARD_TEST_CAMPAIGN_SLUG
    ]
  end

  let(:run_id)             { Time.now.strftime('%Y%m%d%H%M%S') }
  let(:canvas_course_name) { "Wiki Editing Demo Course #{run_id}" }
  let(:dashboard_title)    { 'Wiki Editing Demo' }
  let(:dashboard_school)   { 'StagingTest' }
  let(:canvas_api)         { CanvasApiClient.new }
  let(:provisioned)        { @provisioned ||= {} }
  let(:screenshot_dir) { canvas_shots_dir('student') }

  before do
    missing = required_env.select { |k| ENV[k].to_s.empty? }
    skip("missing env vars: #{missing.join(', ')}") if missing.any?

    canvas_course = canvas_api.create_course(name: canvas_course_name, course_code: "SS-#{run_id}")
    provisioned[:canvas_course_id] = canvas_course['id']
    canvas_api.enroll_user(course_id: canvas_course['id'],
                           user_id: ENV.fetch('CANVAS_TEST_INSTRUCTOR_USER_ID'),
                           role: 'TeacherEnrollment')
    canvas_api.enroll_user(course_id: canvas_course['id'],
                           user_id: ENV.fetch('CANVAS_TEST_STUDENT_USER_ID'),
                           role: 'StudentEnrollment')
  end

  after do
    if provisioned[:canvas_course_id]
      DashboardAdminClient.delete_bindings_for(context_title: canvas_course_name)
      canvas_api.delete_course(course_id: provisioned[:canvas_course_id])
    end
    if provisioned[:dashboard_course_slug]
      DashboardAdminClient.delete_course(slug: provisioned[:dashboard_course_slug])
    end
  end

  it 'captures the in-iframe landing, the enrollment landing, and the student panel' do
    slug = provision_dashboard_course
    bind_course_as_instructor(canvas_course_id: provisioned[:canvas_course_id], course_slug: slug)

    in_student_browser do
      student_walk_to_dashboard(
        canvas_course_id: provisioned[:canvas_course_id],
        email: ENV.fetch('CANVAS_TEST_STUDENT_LOGIN'),
        before_breakout: -> { capture('s01-canvas-iframe-landing') }
      )

      # Capture the in-iframe nav-status view first — it needs only the
      # (roster-auto-linked) enrollment, not a top-level session, so it lands
      # even when the profile's top-level login can't be established.
      capture_student_nav_status

      capture_enrolled_course_home
    end
  end

  # Relaunching the nav tab once enrolled renders the confirmation header
  # right in the iframe — no break-out button.
  def capture_student_nav_status
    in_canvas do
      visit_canvas_course(provisioned[:canvas_course_id])
      click_wiki_education_tab
      # The dashboard course title (the header's course link) is unique to
      # the in-iframe status view; the landing has no course title.
      settle_in_iframe_view(dashboard_title, iframe: canvas_tool_iframe_locator)
      sleep 1
      capture('s06-canvas-nav-status')
    end
  end

  # The enrolled course home + LMS panel need a first-party top-level
  # session (the iframe launch's is partitioned away). If the student
  # profile isn't bootstrapped for top-level dashboard OAuth, skip these two
  # rather than failing — the in-iframe shots above are the load-bearing ones.
  def capture_enrolled_course_home
    in_dashboard { visit '/' }
    ensure_dashboard_logged_in(role: :student)
    in_dashboard { visit "/courses/#{provisioned[:dashboard_course_slug]}" }
    expect(page).to have_content('My Articles', wait: 30)
    dismiss_consent_banner
    capture('s02-student-enrolled-landing')

    await_lms_panel
    scroll_into_view('.lms-integration-status')
    capture('s03-student-course-panel')
  rescue RSpec::Expectations::ExpectationNotMetError, Capybara::ElementNotFound => e
    warn "  [skip] enrolled course-home shots need a top-level student login " \
         "(profile bootstrap): #{e.message.lines.first&.strip}"
  end

  it 'captures the setup-pending view when the instructor has not linked a course' do
    reach_instructor_setup_view(canvas_course_id: provisioned[:canvas_course_id])

    in_student_browser do
      state = student_walk_to_dashboard(canvas_course_id: provisioned[:canvas_course_id],
                                        email: ENV.fetch('CANVAS_TEST_STUDENT_LOGIN'))
      # With a session in the iframe the message renders in place; otherwise
      # the walk broke out and it renders top-level. Capture either.
      unless state == :waiting
        expect(page).to have_content('Wiki Education Dashboard is being set up', wait: 30)
      end
      capture('s04-setup-pending')
    end
  end

  it 'captures the awaiting-approval view when the bound course is unapproved' do
    slug = provision_dashboard_course
    bind_course_as_instructor(canvas_course_id: provisioned[:canvas_course_id], course_slug: slug)
    DashboardAdminClient.unapprove_course(slug:)
    # Roster sync auto-linked + enrolled the student at bind time (email
    # match); undo that so their launch exercises the join flow and hits
    # the awaiting-approval state.
    DashboardAdminClient.unenroll_student(
      course_slug: slug, username: ENV.fetch('WIKIPEDIA_TEST_STUDENT_USERNAME')
    )

    in_student_browser do
      state = student_walk_to_dashboard(canvas_course_id: provisioned[:canvas_course_id],
                                        email: ENV.fetch('CANVAS_TEST_STUDENT_LOGIN'))
      unless state == :waiting
        expect(page).to have_content('awaiting Wiki Education approval', wait: 30)
      end
      capture('s05-enrollment-pending-approval')
    end
  end

  # Create + approve a Dashboard course owned by the test instructor, so
  # it shows up (and is linkable) in the setup view's dropdown.
  def provision_dashboard_course
    course = DashboardAdminClient.create_course(
      title: dashboard_title, school: dashboard_school, term: run_id,
      instructor_username: ENV.fetch('WIKIPEDIA_TEST_INSTRUCTOR_USERNAME')
    )
    provisioned[:dashboard_course_slug] = course['slug']
    DashboardAdminClient.approve_course(slug: course['slug'],
                                        campaign_slug: ENV.fetch('DASHBOARD_TEST_CAMPAIGN_SLUG'))
    course['slug']
  end

  def capture(name)
    save_screenshot_to(screenshot_dir, name)
  end
end
