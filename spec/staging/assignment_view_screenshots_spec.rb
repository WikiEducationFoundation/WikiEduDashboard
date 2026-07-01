# frozen_string_literal: true

require_relative 'spec_helper'

# Captures the assignment_view drill-down (user story I-11, plus the
# student-facing S-11/S-14 panel) as it renders through a real Canvas
# launch: opening a Wikipedia gradebook column's assignment page inside
# Canvas, breaking out of the embedded tool iframe, and landing on the
# dashboard's /lti dispatch — the instructor roster, or the launching
# student's own panel.
#
# ⚠️ SKIPPED — KNOWN GAP (2026-07-01). This spec provisions the exercise
# column via the AUTO-CREATE model (`sync_line_items` -> LtiLineItemSyncWorker
# -> SyncLtiLineItems), whose course-level line items have no resourceLinkId
# and so carry no AGS `lineItemId` on launch. `assignment_launch?` therefore
# returns false and the drill-down launch falls through to the course page —
# the roster is never reached. The assignment_view is only reachable from a
# DEEP-LINK-created assignment (the per-assignment picker / Canvas Find-dialog
# flow that `deep_link_lineitem_diagnostic_spec` demonstrates). To fix, rework
# the provisioning below to create the assignment via deep linking instead of
# `sync_line_items`. Full write-up:
# .claude/canvas_integration/assignment_view_roster_gap-2026-07-01.md
#
# Prerequisite: the assignment_view dispatch (commits adding
# AssignmentViewContext + the /lti branch) must be DEPLOYED to staging.
# The entry point itself — Canvas rendering our tool on an AGS column's
# assignment page — is confirmed by
# `assignment_view_entrypoint_diagnostic_spec`.
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

    # Known gap — see the ⚠️ note at the top of this file. Skip before
    # provisioning so we don't create/tear-down live Canvas state for a walk
    # that can't reach the roster until the provisioning uses deep linking.
    skip('assignment_view roster needs a deep-link-created assignment; ' \
         'auto-created line items carry no lineItemId, so the drill-down ' \
         'falls through to the course page (see KNOWN GAP note above)')

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

  # Bind the course, sync the roster, link + complete the exercise for one
  # student, then sync line items so the exercise column exists as a
  # Canvas assignment. Returns the Canvas assignment id, or :no_student
  # when the student dashboard account isn't present to link.
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
    sync_line_items(binding['id'])
    assignment = eventually do
      canvas_api.find_assignment(course_id: provisioned[:canvas_course_id], name: label)
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

  def sync_line_items(binding_id)
    DashboardConsole.run(<<~RUBY)
      LtiLineItemSyncWorker.new.perform(#{binding_id})
      puts 'ok'
    RUBY
  end

  def capture(name)
    save_screenshot_to(screenshot_dir, name)
  end
end
