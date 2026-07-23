# frozen_string_literal: true

require_relative 'spec_helper'

# Captures the Canvas-side instructor gradebook the Dashboard pushes (see
# SyncLtiGrades): the "Wikipedia account" setup column (LtiSetupProgress) plus the
# "Wikipedia trainings" (LtiTrainingProgress) and per-exercise (LtiBlockProgress)
# completion columns, so an instructor sees who's set up and each student's
# training/exercise progress at a glance. Output goes to
# tmp/canvas-ux-screenshots/canvas_gradebook/ (override with CANVAS_SHOTS_DIR);
# bin/harvest-canvas-screenshots collects it.
#
#   bin/staging-feature-spec spec/staging/canvas_gradebook_screenshots_spec.rb
#
# Scenario — a bound course (with a one-training, one-exercise timeline) and two
# students:
#   - the real test student, set up (linked → "Wikipedia account" 1.0/"✓") and
#     marked complete on the training + exercise (→ those columns post 1.0);
#   - a dedicated, never-launching second student (find_or_create_user), enrolled
#     and roster-discovered but unlinked → "Wikipedia account" 0.0/"not connected"
#     (training/exercise columns stay blank — those grade only linked students).
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
    # A minimal timeline (one training module + one exercise module) so the
    # gradebook carries the "Wikipedia trainings" + exercise columns too.
    provisioned[:timeline] =
      DashboardAdminClient.build_timeline(course_slug: provisioned[:dashboard_course_slug])
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
    # Force 'standard' to auto-create the full column set (account + trainings +
    # per-exercise) for the gradebook shot, rather than driving the Modules
    # import. The gradebook looks the same either way; deep-link-first is the
    # product default now, so this is a gallery shortcut (follow-up: rework
    # onto the import flow).
    DashboardAdminClient.set_granularity(course_slug: slug, granularity: 'standard')
    binding_id = DashboardAdminClient.find_binding(course_slug: slug)['id']

    set_up_connected_student(slug, binding_id)
    add_not_connected_student(canvas_id, binding_id)
    DashboardAdminClient.run_line_item_sync(binding_id:)
    DashboardAdminClient.run_grade_sync(binding_id:)

    capture_instructor_gradebook(canvas_id)
  end

  # Roster-sync so the real student is discovered, link that (sole unlinked)
  # context — the deterministic stand-in for their launch + Wikipedia OAuth —
  # then mark their training + exercise complete so the gradebook columns fill.
  def set_up_connected_student(slug, binding_id)
    DashboardAdminClient.run_roster_sync(binding_id:)
    student = ENV.fetch('WIKIPEDIA_TEST_STUDENT_USERNAME')
    DashboardAdminClient.link_student_context(course_slug: slug, username: student)
    DashboardAdminClient.mark_training_complete(
      username: student, training_module_id: provisioned[:timeline]['training_module_id']
    )
    DashboardAdminClient.mark_exercise_complete(
      course_slug: slug, username: student,
      exercise_module_id: provisioned[:timeline]['exercise_module_id']
    )
  end

  # Enroll a dedicated, never-launching student and roster-sync again so it's
  # discovered as an unlinked (not-connected) context.
  def add_not_connected_student(canvas_id, binding_id)
    # Distinct name (and login) from the real "LTI Test Student" so the two
    # gradebook rows don't read as duplicates when the name column truncates.
    student = canvas_api.find_or_create_user(unique_id: 'lti-unconnected-demo-student',
                                             name: 'Unconnected Demo Student')
    canvas_api.enroll_user(course_id: canvas_id, user_id: student, role: 'StudentEnrollment')
    DashboardAdminClient.run_roster_sync(binding_id:)
  end

  # Log into Canvas as the instructor and screenshot the gradebook once the
  # Dashboard's "Wikipedia account" column has rendered.
  def capture_instructor_gradebook(canvas_id)
    in_canvas do
      ensure_canvas_logged_in_as_instructor
      visit "/courses/#{canvas_id}/gradebook"
      # Wait for a timeline column (proves the trainings/exercise line items,
      # not just the setup column, have rendered).
      expect(page).to have_content('Wikipedia trainings', wait: 40)
      sleep 2 # let the grid finish painting the scores
      capture('c01-canvas-gradebook-progress')
    end
  end

  def capture(name)
    save_screenshot_to(screenshot_dir, name)
  end
end
