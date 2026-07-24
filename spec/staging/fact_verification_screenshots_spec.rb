# frozen_string_literal: true

require_relative 'spec_helper'

# Captures the dedicated-page fact-verification exercise in Canvas — the one
# exercise that runs entirely in the Dashboard (no sandbox), so its drill-down
# is "status + Open exercise" and it has a distinct "In progress" state once a
# student takes a claim. Complements assignment_view (sandbox exercises).
#
# Relies on the shared verification-claim pool having entries so the exercise
# has something to serve; the in-progress shot skips cleanly if it's empty.
#
#   bin/staging-feature-spec spec/staging/fact_verification_screenshots_spec.rb
describe 'Fact-verification exercise screenshots', :staging do
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
  let(:canvas_course_name) { "Wiki Editing Demo (FV) #{run_id}" }
  let(:dashboard_title)    { 'Wiki Editing Demo FV' }
  let(:dashboard_school)   { 'Demo School' }
  let(:student_username)   { ENV.fetch('WIKIPEDIA_TEST_STUDENT_USERNAME') }
  let(:canvas_api)         { CanvasApiClient.new }
  let(:provisioned)        { @provisioned ||= {} }
  let(:screenshot_dir)     { canvas_shots_dir('fact_verification') }

  before do
    missing = required_env.select { |k| ENV[k].to_s.empty? }
    skip("missing env vars: #{missing.join(', ')}") if missing.any?

    canvas_course = canvas_api.create_course(name: canvas_course_name, course_code: "FV-#{run_id}")
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
    # Build the timeline before binding: creating blocks after a binding exists
    # enqueues a line-item sync whose log line pollutes the console JSON.
    provisioned[:timeline] = DashboardAdminClient.build_fact_verification_timeline(
      course_slug: dashboard_course['slug']
    )
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

  it 'captures the fact-verification exercise, instructor and student' do
    slug = provisioned[:dashboard_course_slug]
    canvas_id = provisioned[:canvas_course_id]
    label = provisioned[:timeline]['exercise_line_item_label']

    prepare_course_state(slug:, canvas_id:)
    assignment_id = fact_verification_assignment(canvas_id, label)

    capture_instructor_roster(canvas_id, assignment_id, label)
    capture_student_not_started(canvas_id, assignment_id)
    capture_student_in_progress(slug, canvas_id, assignment_id)
  end

  # Bind deep-link-first, walk the real student through the launch (links +
  # enrolls them), import the columns via the Modules placement, then sync.
  def prepare_course_state(slug:, canvas_id:)
    bind_course_as_instructor(canvas_course_id: canvas_id, course_slug: slug)
    in_student_browser do
      student_walk_to_dashboard(canvas_course_id: canvas_id,
                                email: ENV.fetch('CANVAS_TEST_STUDENT_LOGIN'))
      expect(page).to have_current_path(%r{/courses/}, url: true, wait: 60)
    end
    in_canvas do
      ensure_canvas_logged_in_as_instructor
      import_assignments_via_modules(canvas_id)
    end
    binding = DashboardAdminClient.find_binding(course_slug: slug)
    DashboardAdminClient.run_line_item_sync(binding_id: binding['id'])
    DashboardAdminClient.run_grade_sync(binding_id: binding['id'])
  end

  # Imported assignments (and their module) arrive unpublished; publish so the
  # student can open the exercise, as an instructor would.
  def fact_verification_assignment(canvas_id, label)
    assignment = canvas_api.find_assignment(course_id: canvas_id, name: label)
    expect(assignment).not_to be_nil
    id = assignment['id']
    canvas_api.publish_assignment(course_id: canvas_id, assignment_id: id)
    canvas_api.publish_all_modules(course_id: canvas_id)
    id
  end

  def capture_instructor_roster(canvas_id, assignment_id, label)
    in_canvas do
      ensure_canvas_logged_in_as_instructor
      visit_assignment(canvas_id, assignment_id)
      settle_in_iframe_view(label)
      capture('fv01-instructor-roster')
    end
  end

  def capture_student_not_started(canvas_id, assignment_id)
    in_student_browser do
      in_canvas do
        ensure_canvas_logged_in_as_student
        visit_assignment(canvas_id, assignment_id)
        settle_in_iframe_view('Open exercise')
        capture('fv02-student-not-started')
      end
    end
  end

  # Taking a claim flips the drill-down to "In progress". Skips cleanly if the
  # shared claim pool is empty (nothing to take).
  def capture_student_in_progress(slug, canvas_id, assignment_id)
    taken = DashboardAdminClient.take_verification_claim(course_slug: slug,
                                                         username: student_username)
    if taken == 'no_claim'
      warn '  [skip] fv03 in-progress: the verification-claim pool is empty'
      return
    end

    in_student_browser do
      in_canvas do
        ensure_canvas_logged_in_as_student
        visit_assignment(canvas_id, assignment_id)
        settle_in_iframe_view('In progress')
        capture('fv03-student-in-progress')
      end
    end
  end

  def visit_assignment(canvas_id, assignment_id)
    visit "/courses/#{canvas_id}/assignments/#{assignment_id}"
    sleep 2
  end

  def capture(name)
    save_screenshot_to(screenshot_dir, name)
  end
end
