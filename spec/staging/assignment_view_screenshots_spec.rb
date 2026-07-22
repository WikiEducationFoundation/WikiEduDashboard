# frozen_string_literal: true

require_relative 'spec_helper'

# Captures the in-Canvas assignment drill-downs as they render TODAY: directly
# inside each assignment's tool iframe (no break-out button — the launch token
# authenticates the view; see LtiAnonymousLaunch). Covers all three assignment
# types the deep-link-first import creates:
#   - an exercise (Block) — instructor roster with inline sandbox preview, and
#     the student's own panel;
#   - "Wikipedia account" (setup) — the connection roster (Dashboard-side real
#     name + username, plus a pending never-connected member), and the
#     student's Connected confirmation;
#   - "Wikipedia trainings" (roll-up) — the instructor's linked module list
#     with per-module completion counts above the roster, and the student's
#     due-date table.
#
# Assignments are created the canonical way: the Modules-page bulk import
# (module_index_menu_modal), then a line-item sync binds the columns and a
# grade sync fills scores. The roster is padded with fabricated linked
# students (link_students) so it reads like a real class; a dedicated
# never-launching Canvas student provides the "Not connected" row.
#
#   bin/staging-feature-spec spec/staging/assignment_view_screenshots_spec.rb
describe 'Assignment drill-down screenshots', :staging do
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
  let(:canvas_course_name) { "Wiki Editing Demo (AV) #{run_id}" }
  let(:dashboard_title)    { 'Wiki Editing Demo AV' }
  let(:dashboard_school)   { 'Demo School' }
  let(:student_username)   { ENV.fetch('WIKIPEDIA_TEST_STUDENT_USERNAME') }
  let(:canvas_api)         { CanvasApiClient.new }
  let(:provisioned)        { @provisioned ||= {} }
  let(:screenshot_dir)     { canvas_shots_dir('assignment_view') }
  # Sage-provided test accounts. The first two have sandbox content at
  # User:<name>/Evaluate_an_Article (→ "Completed" + a rendered preview); the
  # real test student walks the launch themselves and contributes their own
  # row, so they aren't fabricated here.
  let(:gallery_students)   { ['Ragetest 9', 'Ragetest 37', 'Ragetest 14'] }
  let(:completed_students) { ['Ragetest 9', 'Ragetest 37'] }
  let(:preview_student)    { 'Ragetest_37' }

  before do
    missing = required_env.select { |k| ENV[k].to_s.empty? }
    skip("missing env vars: #{missing.join(', ')}") if missing.any?

    canvas_course = canvas_api.create_course(name: canvas_course_name, course_code: "AV-#{run_id}")
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
    provisioned[:timeline] = DashboardAdminClient.build_timeline(
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

  it 'captures every assignment type, instructor and student' do
    slug = provisioned[:dashboard_course_slug]
    canvas_id = provisioned[:canvas_course_id]
    timeline = provisioned[:timeline]
    exercise_label = timeline['exercise_line_item_label']

    prepare_course_state(slug:, canvas_id:, timeline:)
    assignments = find_imported_assignments(canvas_id, exercise_label)
    publish_assignments(canvas_id, assignments)

    capture_instructor_views(canvas_id, assignments, exercise_label)
    capture_student_views(canvas_id, assignments)
  end

  # Imported assignments (and their module) arrive unpublished; students
  # can't open them until they're published, as an instructor would do.
  def publish_assignments(canvas_id, assignments)
    assignments.each_value do |assignment_id|
      canvas_api.publish_assignment(course_id: canvas_id, assignment_id:)
    end
    canvas_api.publish_all_modules(course_id: canvas_id)
  end

  # Bind deep-link-first, walk the real student through the launch (links +
  # enrolls them), fabricate the rest of the roster, import all assignments
  # via the Modules placement, then sync line items + grades.
  def prepare_course_state(slug:, canvas_id:, timeline:)
    bind_course_as_instructor(canvas_course_id: canvas_id, course_slug: slug,
                              granularity: 'lumped')
    in_student_browser do
      student_walk_to_dashboard(canvas_course_id: canvas_id,
                                email: ENV.fetch('CANVAS_TEST_STUDENT_LOGIN'))
      expect(page).to have_current_path(%r{/courses/}, url: true, wait: 60)
    end
    populate_roster(slug, timeline)
    in_canvas do
      ensure_canvas_logged_in_as_instructor
      import_assignments_via_modules(canvas_id)
    end
    binding = DashboardAdminClient.find_binding(course_slug: slug)
    DashboardAdminClient.run_line_item_sync(binding_id: binding['id'])
    DashboardAdminClient.run_grade_sync(binding_id: binding['id'])
  end

  def populate_roster(slug, timeline)
    linked = DashboardAdminClient.link_students(course_slug: slug, usernames: gallery_students)
    skip('gallery student accounts not found on staging') if linked.empty?

    completed_students.each do |username|
      DashboardAdminClient.mark_exercise_complete(
        course_slug: slug, username:, exercise_module_id: timeline['exercise_module_id']
      )
    end
    # The real student completes the training, so the trainings views show
    # genuine completion state (status, date, and the instructor count).
    DashboardAdminClient.mark_training_complete(
      username: student_username, training_module_id: timeline['training_module_id']
    )
    add_never_connected_student
  end

  # A dedicated, never-launching Canvas student: roster-synced into a pending
  # (unlinked) context — the "Not connected" row the setup roster exists for.
  def add_never_connected_student
    student = canvas_api.find_or_create_user(unique_id: 'lti-unconnected-demo-student',
                                             name: 'Unconnected Demo Student')
    canvas_api.enroll_user(course_id: provisioned[:canvas_course_id],
                           user_id: student, role: 'StudentEnrollment')
    binding = DashboardAdminClient.find_binding(course_slug: provisioned[:dashboard_course_slug])
    DashboardAdminClient.run_roster_sync(binding_id: binding['id'])
  end

  def find_imported_assignments(canvas_id, exercise_label)
    {
      exercise: canvas_api.find_assignment(course_id: canvas_id, name: exercise_label),
      setup: canvas_api.find_assignment(course_id: canvas_id, name: 'Wikipedia account'),
      trainings: canvas_api.find_assignment(course_id: canvas_id, name: 'Wikipedia trainings')
    }.transform_values { |a| a&.fetch('id') }
  end

  def capture_instructor_views(canvas_id, assignments, exercise_label)
    in_canvas do
      ensure_canvas_logged_in_as_instructor
      visit_assignment(canvas_id, assignments[:exercise])
      settle_in_iframe_view(exercise_label)
      capture('01-exercise-instructor-roster')
      expand_sandbox_preview
      capture('02-exercise-sandbox-preview')

      visit_assignment(canvas_id, assignments[:setup])
      settle_in_iframe_view('Wikipedia account')
      capture('03-setup-instructor-roster')

      visit_assignment(canvas_id, assignments[:trainings])
      settle_in_iframe_view('Wikipedia trainings')
      capture('04-trainings-instructor')
    end
  end

  def capture_student_views(canvas_id, assignments)
    in_student_browser do
      in_canvas do
        ensure_canvas_logged_in_as_student
        visit_assignment(canvas_id, assignments[:exercise])
        settle_in_iframe_view('Your sandbox')
        capture('05-exercise-student-panel')

        visit_assignment(canvas_id, assignments[:setup])
        settle_in_iframe_view('Connected')
        capture('06-setup-student-panel')

        visit_assignment(canvas_id, assignments[:trainings])
        settle_in_iframe_view('Due date')
        capture('07-trainings-student-table')
      end
    end
  end

  def visit_assignment(canvas_id, assignment_id)
    expect(assignment_id).not_to be_nil
    visit "/courses/#{canvas_id}/assignments/#{assignment_id}"
    sleep 2
  end

  # Expand a completed student's "Show" toggle inside the tool iframe and wait
  # for the client-side fetch to render their sandbox content inline.
  def expand_sandbox_preview
    within_frame(first(canvas_assignment_iframe_locator, wait: 10)) do
      find(".lti-sandbox__toggle[data-sandbox-url*='#{preview_student}']").click
      expect(page).to have_css('.lti-sandbox__content--rendered', wait: 25)
      sleep 1
    end
  end

  def capture(name)
    save_screenshot_to(screenshot_dir, name)
  end
end
