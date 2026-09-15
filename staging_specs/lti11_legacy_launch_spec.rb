# frozen_string_literal: true

require_relative 'spec_helper'
require 'open3'

# LTI 1.1 "companion mode" (issue #7026) against the real stack: the account
# tool `bin/canvas-lti11-tool install` put on canvas.wikiedu.org launches
# through the testing LTIAAS tenant's legacy endpoint into staging.
#
# Two things at once. It is a smoke test — instructor first launch through
# setup, student first launch through enrollment, then both relaunches
# rendering in-frame — and it is the *capture* the implementation was waiting
# on: what a legacy launch actually carries (LTIAAS's role normalization,
# `platform.productFamilyCode`, `platform.id` / `user.id` scoping under the
# one global 1.1 registration). Those land in staging's log as `[LTI launch]`
# lines (LTI_LAUNCH_DEBUG is on there) and on the binding + contexts; the spec
# prints them so a run's output is the evidence. Read against the checklist in
# docs/canvas_dev_setup.md ("To verify on the first real legacy launch").
#
# Provisions a fresh Canvas course + dashboard course per run and tears both
# down (pass OR fail), bindings included.
describe 'LTI 1.1 legacy launch (companion mode)', :staging do
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
  let(:canvas_course_name) { "Staging LTI11 #{run_id}" }
  let(:dashboard_title)    { "Staging LTI11 #{run_id}" }
  let(:dashboard_school)   { 'StagingTest' }
  let(:canvas_api)         { CanvasApiClient.new }
  let(:provisioned)        { @provisioned ||= {} }
  let(:shots)              { canvas_shots_dir('lti11') }

  before do
    missing = required_env.select { |k| ENV[k].to_s.empty? }
    skip("missing env vars: #{missing.join(', ')}") if missing.any?

    # Every tab/menu lookup in the helpers goes through `tool_label`; point it
    # at the 1.1 tool for this run (the 1.3 tool keeps its own label).
    ENV['CANVAS_TOOL_LABEL'] = 'wikiedu.org (LTI 1.1)'

    canvas_course = canvas_api.create_course(name: canvas_course_name,
                                             course_code: "LTI11-#{run_id}")
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
    @log_mark = staging_log_length
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

  it 'launches, links and enrolls both personas, and records what LTIAAS sent' do
    slug = provisioned[:dashboard_course_slug]
    course_id = provisioned[:canvas_course_id]

    # --- Instructor: first launch through setup ------------------------------
    bind_course_as_instructor(canvas_course_id: course_id, course_slug: slug)
    binding = binding_snapshot(slug)
    warn "  [lti11] binding: #{binding.inspect}"
    expect(binding['lti_version']).to eq('1.2.0')
    expect(binding['has_service_credentials']).to be false
    expect(binding['lms_family']).to eq('canvas')

    # --- Instructor: relaunch renders the launch-only status view in-frame ---
    in_canvas do
      visit_canvas_course(course_id)
      click_wiki_education_tab
      frame = settle_in_iframe_view(t_lms('connected_accounts'))
      within_frame(frame) do
        expect(page).to have_css('.lti-iframe__course-link')
        expect(page).to have_no_text(t_lti('status.roster_sync_label'))
        expect(page).to have_no_text(t_lti('status.grade_sync_label'))
        expect(page).to have_no_button(t_lti('status.sync_grades'))
        expect(page).to have_no_text(t_lti('status.import_next_step.header'))
      end
      save_screenshot_to(shots, "#{run_id}_instructor_status")
    end

    # --- Student: first launch through enrollment ----------------------------
    in_student_browser do
      state = student_walk_to_dashboard(canvas_course_id: course_id,
                                        email: ENV.fetch('CANVAS_TEST_STUDENT_LOGIN'))
      expect(state).to eq(:landing).or eq(:status)
      expect(page).to have_current_path(%r{/courses/StagingTest/}, url: true, wait: 30)

      # Relaunch: the enrolled student's overview renders in-frame.
      in_canvas do
        visit_canvas_course(course_id)
        click_wiki_education_tab
        frame = settle_in_iframe_view(t_lti('identity.signed_in_as').sub('%{username}', ''))
        within_frame(frame) { expect(page).to have_css('.lti-iframe__course-link') }
        save_screenshot_to(shots, "#{run_id}_student_status")
      end
    end

    roles = DashboardAdminClient.course_roles_for(
      course_slug: slug, username: ENV.fetch('WIKIPEDIA_TEST_STUDENT_USERNAME')
    )
    expect(roles).to include(0) # CoursesUsers::Roles::STUDENT_ROLE

    # --- The capture -----------------------------------------------------------
    contexts = context_snapshot(slug)
    warn "  [lti11] contexts: #{contexts.inspect}"
    expect(contexts.size).to eq(2)

    lines = launch_log_lines_since(@log_mark)
    lines.each { |l| warn "  [lti11] #{l}" }
    expect(lines).not_to be_empty
    expect(lines).to all(include('version="1.2.0"'))
  end

  # What the launch wrote on the binding: version, platform identity, and that
  # no service credentials were persisted for a 1.1 binding.
  def binding_snapshot(course_slug)
    DashboardConsole.run_json(<<~RUBY)
      require 'json'
      course = Course.find_by!(slug: #{course_slug.inspect})
      b = LtiCourseBinding.find_by!(course_id: course.id)
      puts b.attributes.slice('id', 'lti_version', 'lms_id', 'lms_family', 'lms_context_id',
                              'lms_resource_link_id', 'lms_platform_url', 'nrps_url',
                              'ags_lineitems_url')
             .merge('has_service_credentials' => b.ltiaas_service_credentials.present?).to_json
    RUBY
  end

  # The two linked identities: the raw 1.1 user ids and the roles as LTIAAS
  # delivered them (normalized to 1.3 URIs, or the 1.1 forms).
  def context_snapshot(course_slug)
    DashboardConsole.run_json(<<~RUBY)
      require 'json'
      course = Course.find_by!(slug: #{course_slug.inspect})
      b = LtiCourseBinding.find_by!(course_id: course.id)
      puts b.lti_contexts.map { |c|
        { user_lti_id: c.user_lti_id, roles: c.roles, linked: c.user_id.present?,
          instructor: c.instructor?, learner: c.learner? }
      }.to_json
    RUBY
  end

  # Where the web app's Rails log actually lands on staging: Passenger captures
  # the app processes' stdout into Apache's error log (`App <pid> output: …`).
  # `shared/log/staging.log` carries only the Sidekiq and console processes, so
  # a request-time line is never there — the first run of this spec looked in
  # the wrong file and found nothing.
  STAGING_WEB_LOG = '/var/log/apache2/error.log'

  def staging_log_length
    ssh("wc -l < #{STAGING_WEB_LOG}").strip.to_i
  end

  # The `[LTI launch]` diagnostic lines written since the run began (only
  # emitted with LTI_LAUNCH_DEBUG set on staging). Truncated to the claims that
  # matter; they carry no PII by construction (see log_launch_claims).
  def launch_log_lines_since(mark)
    ssh("tail -n +#{mark + 1} #{STAGING_WEB_LOG} | grep -F '[LTI launch]' | cut -c1-900")
      .lines.map(&:strip).reject(&:empty?)
  end

  def ssh(command)
    out, err, status = Open3.capture3('ssh', '-o', 'BatchMode=yes',
                                      "#{DashboardConsole.user}@#{DashboardConsole.host}", command)
    raise "ssh failed: #{err}" unless status.success?

    out
  end
end
