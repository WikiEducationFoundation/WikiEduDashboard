# frozen_string_literal: true

require_relative 'spec_helper'

# Captures the Canvas-side instructor view of Wikipedia-account setup: the
# "Wikipedia account" gradebook column the Dashboard pushes (see LtiSetupProgress
# / SyncLtiGrades), showing which students have connected and which have not.
# Output goes to tmp/canvas-ux-screenshots/canvas_gradebook/ (override with
# CANVAS_SHOTS_DIR); bin/harvest-canvas-screenshots collects it.
#
#   bin/staging-feature-spec spec/staging/canvas_gradebook_screenshots_spec.rb
#
# Scenario — a bound course with two students:
#   - the real test student, set up (linked → the "Wikipedia account" column
#     posts 1.0, comment "✓");
#   - a dedicated, never-launching second student (find_or_create_user), enrolled
#     and roster-discovered but unlinked → posts 0.0, comment "not connected".
# The connected student is linked via the console (link_student_context, the way
# G8 fabricates a launch) rather than a real browser walk, so this stays a single
# (instructor) browser persona and the state is deterministic — link_student_context
# promotes the sole unlinked student context, so we roster-sync and link BEFORE
# enrolling the second student.
#
# NOTE: the column is a points line item, so the gradebook CELL shows the score
# (1 / 0); the "✓" / "not connected" text rides along as the score comment.
describe 'Canvas gradebook — Wikipedia account setup', :staging do
  let(:required_env) do
    %w[
      CANVAS_ADMIN_TOKEN CANVAS_TEST_ACCOUNT_ID
      CANVAS_TEST_INSTRUCTOR_USER_ID
      CANVAS_TEST_INSTRUCTOR_LOGIN CANVAS_TEST_INSTRUCTOR_PASSWORD
      CANVAS_TEST_STUDENT_USER_ID
      WIKIPEDIA_TEST_INSTRUCTOR_USERNAME WIKIPEDIA_TEST_INSTRUCTOR_PASSWORD
      WIKIPEDIA_TEST_STUDENT_USERNAME
      DASHBOARD_TEST_CAMPAIGN_SLUG
    ]
  end

  let(:run_id)             { Time.now.strftime('%Y%m%d%H%M%S') }
  let(:canvas_course_name) { "Wiki Editing Demo Course #{run_id}" }
  let(:dashboard_title)    { 'Wiki Editing Demo' }
  let(:dashboard_school)   { 'StagingTest' }
  let(:canvas_api)         { CanvasApiClient.new }
  let(:provisioned)        { @provisioned ||= {} }
  let(:screenshot_dir)     { canvas_shots_dir('canvas_gradebook') }

  before do
    missing = required_env.select { |k| ENV[k].to_s.empty? }
    skip("missing env vars: #{missing.join(', ')}") if missing.any?

    canvas_course = canvas_api.create_course(name: canvas_course_name, course_code: "GB-#{run_id}")
    provisioned[:canvas_course_id] = canvas_course['id']
    canvas_api.enroll_user(course_id: canvas_course['id'],
                           user_id: ENV.fetch('CANVAS_TEST_INSTRUCTOR_USER_ID'),
                           role: 'TeacherEnrollment')
    canvas_api.enroll_user(course_id: canvas_course['id'],
                           user_id: ENV.fetch('CANVAS_TEST_STUDENT_USER_ID'),
                           role: 'StudentEnrollment')
    dashboard_course = DashboardAdminClient.create_course(
      title: dashboard_title, school: dashboard_school, term: run_id,
      instructor_username: ENV.fetch('WIKIPEDIA_TEST_INSTRUCTOR_USERNAME')
    )
    provisioned[:dashboard_course_slug] = dashboard_course['slug']
    DashboardAdminClient.approve_course(slug: dashboard_course['slug'],
                                        campaign_slug: ENV.fetch('DASHBOARD_TEST_CAMPAIGN_SLUG'))
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

  it 'shows the connected student marked and the not-connected student unmarked' do
    slug = provisioned[:dashboard_course_slug]
    canvas_id = provisioned[:canvas_course_id]
    bind_course_as_instructor(canvas_course_id: canvas_id, course_slug: slug)
    binding_id = DashboardAdminClient.find_binding(course_slug: slug)['id']

    set_up_connected_student(slug, binding_id)
    add_not_connected_student(canvas_id, binding_id)
    DashboardAdminClient.run_grade_sync(binding_id:)

    capture_instructor_gradebook(canvas_id)
  end

  # Roster-sync so the real student is discovered, then link that (sole unlinked)
  # context — the deterministic stand-in for their launch + Wikipedia OAuth.
  def set_up_connected_student(slug, binding_id)
    DashboardAdminClient.run_roster_sync(binding_id:)
    DashboardAdminClient.link_student_context(
      course_slug: slug, username: ENV.fetch('WIKIPEDIA_TEST_STUDENT_USERNAME')
    )
  end

  # Enroll a dedicated, never-launching student and roster-sync again so it's
  # discovered as an unlinked (not-connected) context.
  def add_not_connected_student(canvas_id, binding_id)
    student = canvas_api.find_or_create_user(unique_id: 'lti-unconnected-student',
                                             name: 'LTI Test Student (unconnected)')
    canvas_api.enroll_user(course_id: canvas_id, user_id: student, role: 'StudentEnrollment')
    DashboardAdminClient.run_roster_sync(binding_id:)
  end

  # Log into Canvas as the instructor and screenshot the gradebook once the
  # Dashboard's "Wikipedia account" column has rendered.
  def capture_instructor_gradebook(canvas_id)
    in_canvas do
      ensure_canvas_logged_in_as_instructor
      visit "/courses/#{canvas_id}/gradebook"
      expect(page).to have_content('Wikipedia account', wait: 40)
      sleep 2 # let the grid finish painting the scores
      capture('c01-canvas-gradebook-wikipedia-account')
    end
  end

  def capture(name)
    save_screenshot_to(screenshot_dir, name)
  end
end
