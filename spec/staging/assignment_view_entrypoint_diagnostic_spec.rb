# frozen_string_literal: true

require 'fileutils'
require_relative 'spec_helper'

# DIAGNOSTIC (not a regression spec): answers whether Canvas renders our
# LTI tool on the assignment page of an AGS-created gradebook column — i.e.
# whether the `assignment_view` placement fires for the plain, course-level
# line items SyncLtiLineItems creates (no resourceLinkId). If it does, the
# assignment_view drill-down has a real entry point worth screenshotting
# once deployed; if it doesn't, our line items need to become
# tool-associated assignments first.
#
# Independent of the dashboard code version under test: this observes
# Canvas's rendering behavior, so it's meaningful against current staging
# even before the assignment_view dispatch is deployed.
#
# Provisions a fresh Canvas + dashboard course, binds, syncs line items,
# opens the exercise column's assignment page, and reports + screenshots
# what renders. Tears everything down on completion (pass or fail).
describe 'DIAGNOSTIC: assignment_view entry point on an AGS column', :staging do
  let(:required_env) do
    %w[
      CANVAS_ADMIN_TOKEN CANVAS_TEST_ACCOUNT_ID
      CANVAS_TEST_INSTRUCTOR_USER_ID
      CANVAS_TEST_INSTRUCTOR_LOGIN CANVAS_TEST_INSTRUCTOR_PASSWORD
      WIKIPEDIA_TEST_INSTRUCTOR_USERNAME WIKIPEDIA_TEST_INSTRUCTOR_PASSWORD
      DASHBOARD_TEST_CAMPAIGN_SLUG
    ]
  end

  let(:run_id)             { Time.now.strftime('%Y%m%d%H%M%S') }
  let(:canvas_course_name) { "Staging AV-diag #{run_id}" }
  let(:dashboard_title)    { "Staging AV diag #{run_id}" }
  let(:dashboard_school)   { 'StagingTest' }
  let(:canvas_api)         { CanvasApiClient.new }
  let(:provisioned)        { @provisioned ||= {} }
  let(:artifact_dir)       { File.expand_path('../../tmp/staging-diagnostics', __dir__) }

  before do
    missing = required_env.select { |k| ENV[k].to_s.empty? }
    skip("missing env vars: #{missing.join(', ')}") if missing.any?

    canvas_course = canvas_api.create_course(name: canvas_course_name, course_code: "AVD-#{run_id}")
    provisioned[:canvas_course_id] = canvas_course['id']
    canvas_api.enroll_user(course_id: canvas_course['id'],
                           user_id: ENV.fetch('CANVAS_TEST_INSTRUCTOR_USER_ID'),
                           role: 'TeacherEnrollment')
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

  it 'reports whether the WED tool renders on the exercise column assignment page' do
    slug = provisioned[:dashboard_course_slug]
    label = provisioned[:timeline]['exercise_line_item_label']
    bind_course_as_instructor(canvas_course_id: provisioned[:canvas_course_id], course_slug: slug)

    binding = DashboardAdminClient.find_binding(course_slug: slug)
    expect(binding).not_to be_nil
    sync_line_items(binding['id'])

    assignment = eventually do
      canvas_api.find_assignment(course_id: provisioned[:canvas_course_id], name: label)
    end

    if assignment.nil?
      warn "  [diag] no AGS assignment named #{label.inspect} found — line-item sync " \
           'may not have created it; cannot test the assignment page.'
    else
      warn "  [diag] exercise assignment: id=#{assignment['id']} " \
           "submission_types=#{assignment['submission_types'].inspect}"
      tool_present = open_assignment_and_detect_tool(assignment['id'])
      capture_assignment_page
      warn "  [diag] VERDICT: WED tool iframe on the assignment page => " \
           "#{tool_present ? 'PRESENT' : 'ABSENT'}"
    end
  end

  def sync_line_items(binding_id)
    DashboardConsole.run(<<~RUBY)
      LtiLineItemSyncWorker.new.perform(#{binding_id})
      puts 'ok'
    RUBY
  end

  # Visit the assignment's page in the instructor's Canvas session and
  # report whether Canvas embedded our external-tool iframe there (the
  # assignment_view placement). submission_types hints at it; the iframe
  # is the real signal.
  def open_assignment_and_detect_tool(assignment_id)
    in_canvas do
      ensure_canvas_logged_in_as_instructor
      visit "/courses/#{provisioned[:canvas_course_id]}/assignments/#{assignment_id}"
      sleep 3
      page.has_css?('iframe.tool_launch, iframe[data-lti-launch="true"], iframe#tool_content',
                    wait: 5)
    end
  end

  def capture_assignment_page
    FileUtils.mkdir_p(artifact_dir)
    path = File.join(artifact_dir, 'assignment_view_entrypoint.png')
    page.save_screenshot(path)
    warn "  [diag] screenshot: #{path}"
  end
end
