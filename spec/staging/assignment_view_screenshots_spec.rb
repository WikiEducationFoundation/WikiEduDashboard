# frozen_string_literal: true

require_relative 'spec_helper'

# Captures the assignment_view drill-down (user story I-11, plus the
# student-facing S-11/S-14 panel) as it renders through a real Canvas
# launch: opening a Wikipedia gradebook column's assignment page inside
# Canvas, breaking out of the embedded tool iframe, and landing on the
# dashboard's /lti dispatch — the instructor roster, or the launching
# student's own panel.
#
# The assignment_view is reached from a DEEP-LINK-created assignment: its launch
# carries the deep-link `resource` marker that `assignment_launch?` keys on. That
# launch does NOT carry a scoped AGS line-item URL, so `ResolveAssignmentLineItem`
# maps the marker to the line item SyncLtiLineItems already creates for the
# exercise on binding. The provisioning below therefore both syncs line items
# (`run_line_item_sync`) and creates the launchable Canvas assignment through the
# deep-link picker (`create_deep_linked_assignment`) — named distinctly from the
# auto-synced column so it's unambiguously findable.
#
# Prerequisite: deployed staging must carry the deep-link fixes — the picker's
# framing fix (deep_link/deep_link_select in #allow_iframe), `assignment_launch?`
# recognizing the `resource` marker, and `ResolveAssignmentLineItem` resolving via
# the existing line item — or the launch falls through to the course page.
#
#   bin/staging-feature-spec spec/staging/assignment_view_screenshots_spec.rb
#
# Provisions a fresh Canvas + dashboard course with one linked student who
# has completed the exercise (so the roster shows a Completed row with a
# sandbox link), captures the screenshots, and tears everything down on
# completion. Skips cleanly if the student dashboard account doesn't exist
# yet (run g7 once to create it).
describe 'Assignment view drill-down screenshots', :staging do
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
  let(:student_canvas_id)  { ENV.fetch('CANVAS_TEST_STUDENT_USER_ID') }
  let(:canvas_api)         { CanvasApiClient.new }
  let(:provisioned)        { @provisioned ||= {} }
  let(:screenshot_dir)     { canvas_shots_dir('assignment_view') }

  before do
    missing = required_env.select { |k| ENV[k].to_s.empty? }
    skip("missing env vars: #{missing.join(', ')}") if missing.any?

    canvas_course = canvas_api.create_course(name: canvas_course_name, course_code: "AV-#{run_id}")
    provisioned[:canvas_course_id] = canvas_course['id']
    canvas_api.enroll_user(course_id: canvas_course['id'],
                           user_id: ENV.fetch('CANVAS_TEST_INSTRUCTOR_USER_ID'),
                           role: 'TeacherEnrollment')
    canvas_api.enroll_user(course_id: canvas_course['id'],
                           user_id: student_canvas_id, role: 'StudentEnrollment')
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

  it 'captures the instructor roster and the student panel' do
    slug = provisioned[:dashboard_course_slug]
    timeline = provisioned[:timeline]
    label = timeline['exercise_line_item_label']

    assignment_id = prepare_completed_exercise_column(slug:, timeline:, label:)
    skip('student account not found on dashboard; run g7 once') if assignment_id == :no_student

    capture_instructor_roster(assignment_id:, label:)
    capture_student_panel(assignment_id:)
  end

  # Bind the course, sync the roster + line items, link + complete the exercise for
  # one student, then create a launchable deep-link assignment whose launch resolves
  # (via its `resource` marker) to the synced exercise line item. Returns the Canvas
  # assignment id, or :no_student when the student dashboard account isn't present.
  def prepare_completed_exercise_column(slug:, timeline:, label:)
    bind_course_as_instructor(canvas_course_id: provisioned[:canvas_course_id], course_slug: slug)
    binding = DashboardAdminClient.find_binding(course_slug: slug)
    DashboardAdminClient.run_roster_sync(binding_id: binding['id'])
    linked = DashboardAdminClient.link_student_context(course_slug: slug,
                                                       username: student_username)
    return :no_student if linked == 'no_user'

    DashboardAdminClient.mark_exercise_complete(
      course_slug: slug, username: student_username,
      exercise_module_id: timeline['exercise_module_id']
    )
    DashboardAdminClient.run_line_item_sync(binding_id: binding['id'])
    create_and_find_drilldown_assignment(label:)
  end

  # Create the launchable deep-link assignment (named distinctly from the
  # auto-synced column so find_assignment is unambiguous) and return its id.
  def create_and_find_drilldown_assignment(label:)
    name = "#{label} (drill-down)"
    create_deep_linked_assignment(course_id: provisioned[:canvas_course_id],
                                  gradable_label: label, assignment_name: name)
    assignment = eventually do
      canvas_api.find_assignment(course_id: provisioned[:canvas_course_id], name:)
    end
    expect(assignment).not_to be_nil
    assignment['id']
  end

  def capture_instructor_roster(assignment_id:, label:)
    in_canvas do
      ensure_canvas_logged_in_as_instructor
      visit "/courses/#{provisioned[:canvas_course_id]}/assignments/#{assignment_id}"
      sleep 3
      capture('01-canvas-assignment-page')
      break_out_of_canvas_iframe(role: :instructor, iframe: canvas_assignment_iframe_locator)
    end
    dismiss_consent_banner
    expect(page).to have_content(label, wait: 20)
    expect(page).to have_content('Completed')
    capture('02-instructor-roster')
  end

  def capture_student_panel(assignment_id:)
    in_student_browser do
      in_canvas do
        ensure_canvas_logged_in_as_student
        visit "/courses/#{provisioned[:canvas_course_id]}/assignments/#{assignment_id}"
        sleep 3
        break_out_of_canvas_iframe(role: :student, iframe: canvas_assignment_iframe_locator)
      end
      dismiss_consent_banner
      expect(page).to have_content('Your sandbox', wait: 20)
      capture('03-student-panel')
    end
  end

  def capture(name)
    save_screenshot_to(screenshot_dir, name)
  end
end
