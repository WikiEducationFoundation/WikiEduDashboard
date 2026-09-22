# frozen_string_literal: true

require_relative 'spec_helper'

# G8: training-completion score push. Completing the trainings for a linked
# student and running grade sync should land a 1.0 on the "Wikipedia trainings"
# gradebook column in Canvas, with an "N of N trainings completed" comment
# (smoke-test step G8).
#
# That column is a roll-up over every training-kind module in the course's
# timeline, and the timeline comes from the real `researchwrite` wizard, which
# carries several — so reaching 1.0 means completing all of them, not one. This
# spec completed a single module until 2026-08-17, back when the fixture built a
# minimal hand-made timeline; against a wizard timeline that scores a fraction,
# and because `completed_at` is per (user, module) rather than per course, the
# fraction drifted upward as earlier runs left completions behind.
#
# Single browser persona (instructor). The student is enrolled on the
# Canvas side via the REST API and linked via console — fabricating the
# state a real student launch produces, which G7 covers for real — so this
# spec stays focused on the grade-push path. The score is read back through
# the Canvas REST submissions API (the same fact the gradebook renders),
# which is far steadier than scraping Canvas's gradebook SPA.
#
# Provisions a fresh Canvas course + dashboard course (with timeline) per
# run and tears both down on completion (pass OR fail).
describe 'G8: training score push', :staging do
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
  let(:canvas_course_name) { "Staging G8 #{run_id}" }
  let(:dashboard_title)    { "Staging G8 #{run_id}" }
  let(:dashboard_school)   { 'StagingTest' }
  let(:student_username)   { ENV.fetch('WIKIPEDIA_TEST_STUDENT_USERNAME') }
  let(:student_canvas_id)  { ENV.fetch('CANVAS_TEST_STUDENT_USER_ID') }
  let(:canvas_api)         { CanvasApiClient.new }
  let(:provisioned)        { @provisioned ||= {} }

  before do
    missing = required_env.select { |k| ENV[k].to_s.empty? }
    skip("missing env vars: #{missing.join(', ')}") if missing.any?

    canvas_course = canvas_api.create_course(name: canvas_course_name, course_code: "G8-#{run_id}")
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

  it 'pushes a 1.0 to the Wikipedia trainings column with a completion comment' do
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

    # The column is the rolled-up "Wikipedia trainings" one, so 1.0 means every
    # training in the timeline is done — not just one. The wizard timeline
    # carries several.
    count = DashboardAdminClient.complete_all_trainings(course_slug: slug,
                                                        username: student_username)
    expect(count).to be > 0
    DashboardAdminClient.run_line_item_sync(binding_id: binding['id'])
    DashboardAdminClient.run_grade_sync(binding_id: binding['id'])

    label = timeline['training_line_item_label']
    submission = fetch_scored_submission(label:)
    expect(submission).not_to be_nil
    expect(submission['score'].to_f).to be_within(0.01).of(1.0)
    expect(await_comment_text(label:)).to include("#{count} of #{count} trainings completed")
  end

  def fetch_scored_submission(label:)
    course_id = provisioned[:canvas_course_id]
    eventually do
      assignment = canvas_api.find_assignment(course_id:, name: label)
      next unless assignment

      sub = canvas_api.submission(course_id:, assignment_id: assignment['id'],
                                  user_id: student_canvas_id)
      sub if sub && !sub['score'].nil?
    end
  end

  # Canvas creates the AGS comment a beat after it stores the score, so the
  # response that first carried the score usually has no comments on it yet.
  # Re-read until one lands instead of asserting against that first response.
  def await_comment_text(label:)
    course_id = provisioned[:canvas_course_id]
    assignment = canvas_api.find_assignment(course_id:, name: label)
    eventually(attempts: 15) do
      sub = canvas_api.submission(course_id:, assignment_id: assignment['id'],
                                  user_id: student_canvas_id)
      text = sub ? comment_text(sub) : ''
      text unless text.empty?
    end.to_s
  end

  def comment_text(submission)
    Array(submission['submission_comments']).map { |c| c['comment'].to_s }.join("\n")
  end
end
