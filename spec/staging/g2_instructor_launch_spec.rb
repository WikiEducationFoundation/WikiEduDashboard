# frozen_string_literal: true

require_relative 'spec_helper'

# G2: instructor's first launch from Canvas through the dashboard's
# setup view ending at /courses/<slug>, the LtiCourseBinding now
# persisted with the right course id.
#
# Provisions a fresh Canvas course + dashboard course per run; tears
# both down on completion (pass OR fail) so re-runs are hermetic.
# Browser-driving steps assume the persistent profile is already
# bootstrapped — see `docs/staging_feature_specs.md` for the one-time
# Canvas-login + Wikipedia-OAuth-approval procedure.
#
# Required env (in `.env.staging-tests`):
#   CANVAS_ADMIN_TOKEN
#   CANVAS_TEST_ACCOUNT_ID
#   CANVAS_TEST_INSTRUCTOR_USER_ID
#   WIKIPEDIA_TEST_INSTRUCTOR_USERNAME
#   DASHBOARD_TEST_CAMPAIGN_SLUG
describe 'G2: instructor first launch', :staging do
  REQUIRED_ENV = %w[
    CANVAS_ADMIN_TOKEN CANVAS_TEST_ACCOUNT_ID
    CANVAS_TEST_INSTRUCTOR_USER_ID
    CANVAS_TEST_INSTRUCTOR_LOGIN CANVAS_TEST_INSTRUCTOR_PASSWORD
    WIKIPEDIA_TEST_INSTRUCTOR_USERNAME WIKIPEDIA_TEST_INSTRUCTOR_PASSWORD
    DASHBOARD_TEST_CAMPAIGN_SLUG
  ].freeze

  let(:run_id)             { Time.now.strftime('%Y%m%d%H%M%S') }
  let(:canvas_course_name) { "Staging G2 #{run_id}" }
  let(:dashboard_title)    { "Staging G2 #{run_id}" }
  let(:dashboard_school)   { 'StagingTest' }
  let(:dashboard_term)     { run_id }
  let(:canvas_api)         { CanvasApiClient.new }
  let(:provisioned)        { @provisioned ||= {} }

  before do
    missing = REQUIRED_ENV.select { |k| ENV[k].to_s.empty? }
    skip("missing env vars: #{missing.join(', ')}") if missing.any?

    canvas_course = canvas_api.create_course(name: canvas_course_name, course_code: "G2-#{run_id}")
    provisioned[:canvas_course_id] = canvas_course['id']
    canvas_api.enroll_user(course_id: canvas_course['id'],
                           user_id: ENV.fetch('CANVAS_TEST_INSTRUCTOR_USER_ID'),
                           role: 'TeacherEnrollment')
    dashboard_course = DashboardAdminClient.create_course(
      title: dashboard_title, school: dashboard_school, term: dashboard_term,
      instructor_username: ENV.fetch('WIKIPEDIA_TEST_INSTRUCTOR_USERNAME')
    )
    provisioned[:dashboard_course_id] = dashboard_course['id']
    provisioned[:dashboard_course_slug] = dashboard_course['slug']
    DashboardAdminClient.approve_course(slug: dashboard_course['slug'],
                                        campaign_slug: ENV.fetch('DASHBOARD_TEST_CAMPAIGN_SLUG'))
  end

  after do
    if provisioned[:canvas_course_id]
      canvas_api.delete_course(course_id: provisioned[:canvas_course_id])
    end
    if provisioned[:dashboard_course_slug]
      DashboardAdminClient.delete_course(slug: provisioned[:dashboard_course_slug])
    end
  end

  it 'walks the launch flow from Canvas through setup to /courses/<slug>' do
    in_canvas do
      ensure_canvas_logged_in_as_instructor
      visit_canvas_course(provisioned[:canvas_course_id])
      click_wiki_education_tab
      break_out_of_canvas_iframe(role: :instructor)
    end

    # Now at top level in the new tab. The OAuth bounce should be silent
    # because the profile already has the Wikipedia OAuth grant.
    dismiss_consent_banner
    complete_dashboard_setup(course_slug: provisioned[:dashboard_course_slug])

    expect(page.current_url).to include("/courses/#{provisioned[:dashboard_course_slug]}")

    binding = DashboardAdminClient.find_binding(course_slug: provisioned[:dashboard_course_slug])
    expect(binding).to include('course_id' => provisioned[:dashboard_course_id])
    expect(binding['gradebook_granularity']).to eq('lumped')
  end
end
