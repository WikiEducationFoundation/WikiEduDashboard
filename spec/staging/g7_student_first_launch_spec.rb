# frozen_string_literal: true

require_relative 'spec_helper'

# G7: student's first launch from Canvas. Given a bound, approved course
# with the student enrolled on the Canvas side, the student clicks the
# Wiki Education Dashboard tab, breaks out of the iframe, completes
# Wikipedia OAuth, and lands enrolled on /courses/<slug> — the real
# auto-enroll path an actual student walks (smoke-test step G7).
#
# Two browser personas in one run: the instructor binds the course in the
# default profile, then the student walks their launch in a *separate*
# Chrome profile (`in_student_browser`) so the two Canvas/Wikipedia
# sessions don't collide. Both profiles must be bootstrapped once — see
# docs/staging_feature_specs.md.
#
# Provisions a fresh Canvas course + dashboard course per run and tears
# both down on completion (pass OR fail). The student's dashboard User is
# created automatically by their first Wikipedia OAuth, so this spec also
# doubles as the bootstrap that later score specs (G8/G9) rely on.
describe 'G7: student first launch', :staging do
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
  let(:canvas_course_name) { "Staging G7 #{run_id}" }
  let(:dashboard_title)    { "Staging G7 #{run_id}" }
  let(:dashboard_school)   { 'StagingTest' }
  let(:canvas_api)         { CanvasApiClient.new }
  let(:provisioned)        { @provisioned ||= {} }

  before do
    missing = required_env.select { |k| ENV[k].to_s.empty? }
    skip("missing env vars: #{missing.join(', ')}") if missing.any?

    canvas_course = canvas_api.create_course(name: canvas_course_name, course_code: "G7-#{run_id}")
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

  it 'auto-enrolls the student as STUDENT after their OAuth launch' do
    slug = provisioned[:dashboard_course_slug]
    bind_course_as_instructor(canvas_course_id: provisioned[:canvas_course_id],
                              course_slug: slug)

    in_student_browser do
      in_canvas do
        ensure_canvas_logged_in_as_student
        visit_canvas_course(provisioned[:canvas_course_id])
        click_wiki_education_tab
        break_out_of_canvas_iframe(role: :student)
      end
      dismiss_consent_banner
      # If the student is a brand-new dashboard user, `check_onboarded`
      # routes them to /onboarding (carrying return_to=/lti?ltik=...);
      # walk it like a real student would. No-ops on a returning student.
      walk_through_onboarding(real_name: 'LTI Test Student',
                              email: ENV.fetch('CANVAS_TEST_STUDENT_LOGIN'))
      expect(page).to have_current_path(%r{/courses/StagingTest/}, url: true, wait: 30)
    end

    roles = DashboardAdminClient.course_roles_for(
      course_slug: slug, username: ENV.fetch('WIKIPEDIA_TEST_STUDENT_USERNAME')
    )
    # CoursesUsers::Roles::STUDENT_ROLE == 0
    expect(roles).to include(0)
  end
end
