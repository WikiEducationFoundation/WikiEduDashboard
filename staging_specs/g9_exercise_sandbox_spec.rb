# frozen_string_literal: true

require_relative 'spec_helper'

# G9: exercise-completion push. Marking the exercise module complete for a linked
# student and running grade sync should register the exercise's gradebook column
# in Canvas as submitted but UNGRADED — Submitted + PendingManual, no score.
# Exercise work is the instructor's to judge, so as of 2026-08-03 we stop short
# of claiming a grade and let Canvas queue it for grading (see LtiBlockProgress).
# This spec asserted the old 1.0 until 2026-08-17; a score appearing here now is
# the regression to catch.
#
# The comment must NOT carry the student's sandbox URL: that URL embeds their
# Wikipedia username, and an AGS comment is visible to TAs/co-instructors/the
# registrar/CSV exports — a FERPA correlation we deliberately don't persist in
# Canvas (removed in commit 98c1d8ade). Instructors reach the sandbox through the
# role-gated in-Canvas assignment_view instead.
#
# Single browser persona (instructor); the student is enrolled via the Canvas
# REST API and linked via console, as in G8. The submission + comment are read back
# through the Canvas REST submissions API.
#
# Provisions a fresh Canvas course + dashboard course (with timeline) per
# run and tears both down on completion (pass OR fail). Skips cleanly if
# the staging training library has no exercise module with a
# sandbox_location to grade.
describe 'G9: exercise score push', :staging do
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
  let(:canvas_course_name) { "Staging G9 #{run_id}" }
  let(:dashboard_title)    { "Staging G9 #{run_id}" }
  let(:dashboard_school)   { 'StagingTest' }
  let(:student_username)   { ENV.fetch('WIKIPEDIA_TEST_STUDENT_USERNAME') }
  let(:student_canvas_id)  { ENV.fetch('CANVAS_TEST_STUDENT_USER_ID') }
  let(:canvas_api)         { CanvasApiClient.new }
  let(:provisioned)        { @provisioned ||= {} }

  before do
    missing = required_env.select { |k| ENV[k].to_s.empty? }
    skip("missing env vars: #{missing.join(', ')}") if missing.any?

    canvas_course = canvas_api.create_course(name: canvas_course_name, course_code: "G9-#{run_id}")
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

  it 'submits the exercise column ungraded, without leaking the sandbox URL' do
    slug = provisioned[:dashboard_course_slug]
    timeline = provisioned[:timeline]
    bind_course_as_instructor(canvas_course_id: provisioned[:canvas_course_id], course_slug: slug)

    # Deep-link-first: linking creates no columns, so seed the set the Modules
    # import would create and let discovery bind them, exactly as a real import
    # does — without driving the picker through a browser.
    DashboardAdminClient.import_all_columns(course_slug: slug)

    binding = DashboardAdminClient.find_binding(course_slug: slug)
    DashboardAdminClient.run_roster_sync(binding_id: binding['id'])
    linked = DashboardAdminClient.link_student_context(course_slug: slug,
                                                       username: student_username)
    skip('student dashboard account not found; run G7 once to create it') if linked == 'no_user'

    DashboardAdminClient.mark_exercise_complete(
      course_slug: slug, username: student_username,
      exercise_module_id: timeline['exercise_module_id']
    )
    DashboardAdminClient.run_line_item_sync(binding_id: binding['id'])
    DashboardAdminClient.run_grade_sync(binding_id: binding['id'])

    submission = fetch_submitted_submission(label: timeline['exercise_line_item_label'])
    expect(submission).not_to be_nil

    # Exercise work is the instructor's to judge, so since 2026-08-03 a complete
    # block is reported Submitted + PendingManual and carries NO score — Canvas
    # queues it for grading rather than us claiming full marks for a ticked
    # checkbox (see LtiBlockProgress). Asserting the absence is the point: a 1.0
    # here would be the regression.
    expect(submission['score']).to be_nil
    expect(submission['workflow_state']).not_to eq('graded')

    # The comment must NOT carry the sandbox URL / username (FERPA — see the
    # class comment).
    text = comment_text(submission)
    expect(text).not_to include('/wiki/User:')
    expect(text).not_to include(student_username)
    expect(text).not_to include(timeline['exercise_sandbox_location'])
  end

  # The push registers as a submission attempt rather than a score, so `attempt`
  # is what says it landed. Filtering on a score instead — as this spec used to —
  # can never match an intentionally ungraded column.
  def fetch_submitted_submission(label:)
    course_id = provisioned[:canvas_course_id]
    eventually do
      assignment = canvas_api.find_assignment(course_id:, name: label)
      next unless assignment

      sub = canvas_api.submission(course_id:, assignment_id: assignment['id'],
                                  user_id: student_canvas_id)
      sub if sub && sub['attempt'].to_i.positive?
    end
  end

  def comment_text(submission)
    Array(submission['submission_comments']).map { |c| c['comment'].to_s }.join("\n")
  end
end
