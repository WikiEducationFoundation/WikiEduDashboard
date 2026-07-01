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
        before_breakout: -> { sleep 2; capture('s01-canvas-iframe-landing') }
      )
      expect(page).to have_current_path(%r{/courses/StagingTest/}, url: true, wait: 30)
      capture('s02-student-enrolled-landing')

      expect(page).to have_css('.lms-integration-status', wait: 30)
      scroll_into_view('.lms-integration-status')
      capture('s03-student-course-panel')
    end
  end

  it 'captures the setup-pending view when the instructor has not linked a course' do
    reach_instructor_setup_view(canvas_course_id: provisioned[:canvas_course_id])

    in_student_browser do
      student_walk_to_dashboard
      expect(page).to have_content('Wiki Education Dashboard is being set up', wait: 30)
      capture('s04-setup-pending')
    end
  end

  it 'captures the awaiting-approval view when the bound course is unapproved' do
    slug = provision_dashboard_course
    bind_course_as_instructor(canvas_course_id: provisioned[:canvas_course_id], course_slug: slug)
    DashboardAdminClient.unapprove_course(slug:)

    in_student_browser do
      student_walk_to_dashboard
      expect(page).to have_content('awaiting Wiki Education approval', wait: 30)
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

  # The student-side Canvas walk: log into Canvas, open the course's Wiki
  # Education tab, break out of the iframe through Wikipedia OAuth, and
  # land at top level on the dashboard. `before_breakout` runs after the
  # tab is open but before the break-out, for capturing the in-iframe
  # landing. Must be called inside `in_student_browser`.
  def student_walk_to_dashboard(before_breakout: nil)
    in_canvas do
      ensure_canvas_logged_in_as_student
      visit_canvas_course(provisioned[:canvas_course_id])
      click_wiki_education_tab
      before_breakout&.call
      break_out_of_canvas_iframe(role: :student)
    end
    dismiss_consent_banner
    # A brand-new dashboard user gets routed through /onboarding before
    # the LTI launch resumes; walk it. Silent no-op on a returning user.
    walk_through_onboarding(real_name: 'LTI Test Student',
                            email: ENV.fetch('CANVAS_TEST_STUDENT_LOGIN'))
  end

  def capture(name)
    save_screenshot_to(screenshot_dir, name)
  end
end
