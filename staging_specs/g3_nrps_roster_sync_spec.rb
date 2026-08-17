# frozen_string_literal: true

require_relative 'spec_helper'

# G3: NRPS roster sync. After an instructor binds a Canvas course to a
# dashboard course (which captures the LTIAAS service_key), a Canvas-side
# student enrollment should surface as an LtiContext row once roster sync
# runs — discovered but Wikipedia-unlinked (user_id nil), because Canvas's
# NRPS strips email by default so there's nothing to auto-link on (see
# smoke-test notes [G4a]/[G5a]). The instructor, who linked during their
# own launch, stays linked.
#
# Single browser persona (instructor). The student is enrolled in Canvas
# via the REST API, not a browser — the real student-launch UX is G7's job.
#
# Provisions a fresh Canvas course + dashboard course per run; tears both
# down on completion (pass OR fail). Assumes the instructor profile is
# already bootstrapped (see docs/staging_feature_specs.md).
describe 'G3: NRPS roster sync', :staging do
  # A local (per-example) value rather than a top-level constant: each
  # staging spec needs a slightly different env list, and constants
  # declared in a describe block leak into the shared namespace and
  # clobber each other across files (see project spec conventions).
  let(:required_env) do
    %w[
      CANVAS_ADMIN_TOKEN CANVAS_TEST_ACCOUNT_ID
      CANVAS_TEST_INSTRUCTOR_USER_ID
      CANVAS_TEST_INSTRUCTOR_LOGIN CANVAS_TEST_INSTRUCTOR_PASSWORD
      CANVAS_TEST_STUDENT_USER_ID
      WIKIPEDIA_TEST_INSTRUCTOR_USERNAME WIKIPEDIA_TEST_INSTRUCTOR_PASSWORD
      DASHBOARD_TEST_CAMPAIGN_SLUG
    ]
  end

  let(:run_id)             { Time.now.strftime('%Y%m%d%H%M%S') }
  let(:canvas_course_name) { "Staging G3 #{run_id}" }
  let(:dashboard_title)    { "Staging G3 #{run_id}" }
  let(:dashboard_school)   { 'StagingTest' }
  let(:canvas_api)         { CanvasApiClient.new }
  let(:provisioned)        { @provisioned ||= {} }

  before do
    missing = required_env.select { |k| ENV[k].to_s.empty? }
    skip("missing env vars: #{missing.join(', ')}") if missing.any?

    canvas_course = canvas_api.create_course(name: canvas_course_name, course_code: "G3-#{run_id}")
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

  it 'discovers the enrolled student and keeps the instructor linked' do
    slug = provisioned[:dashboard_course_slug]
    bind_course_as_instructor(canvas_course_id: provisioned[:canvas_course_id],
                              course_slug: slug)

    binding = DashboardAdminClient.find_binding(course_slug: slug)
    synced_at = DashboardAdminClient.run_roster_sync(binding_id: binding['id'])
    expect(synced_at).not_to be_empty

    contexts = DashboardAdminClient.list_contexts(course_slug: slug)
    instructor = contexts.find { |c| c['roles'].any? { |r| r.include?('Instructor') } }
    student = contexts.find { |c| c['roles'].any? { |r| r.include?('Learner') } }

    expect(contexts.size).to be >= 2
    expect(instructor).not_to be_nil
    expect(instructor['user_id']).not_to be_nil
    expect(student).not_to be_nil
    expect(student['user_id']).to be_nil
  end
end
