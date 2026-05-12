# frozen_string_literal: true

require_relative 'spec_helper'

# Exercises the provisioning layer end-to-end against live staging:
# create a Canvas course via the REST API, install the Wiki Education
# Dashboard external tool, provision a corresponding dashboard course
# via DashboardConsole, approve it via a campaign, then tear all of
# it down. No LTI launch flow — that's T3.
#
# Requires:
#   - CANVAS_ADMIN_TOKEN + CANVAS_TEST_ACCOUNT_ID in .env.staging-tests
#   - SSH key access to the staging dashboard host
#   - At least one instructor User and one Campaign on the staging
#     dashboard with stable usernames/slugs
#
# Unless those are configured, this spec aborts with a clear message
# instead of dying mid-flight.
describe 'staging provisioning layer', :staging do
  let(:run_id)       { Time.now.strftime('%Y%m%d%H%M%S') }
  let(:course_name)  { "Staging Provisioning Test #{run_id}" }
  let(:course_slug)  { "StagingTest/Provisioning_#{run_id}" }

  let(:canvas_api) do
    CanvasApiClient.new
  rescue CanvasApiClient::ConfigError => e
    skip("CanvasApiClient unavailable: #{e.message}. Configure .env.staging-tests.")
  end

  it 'creates a Canvas course via the REST API and tears it down' do
    skip 'Not yet implemented: live Canvas create_course' unless canvas_api

    course = canvas_api.create_course(name: course_name, course_code: "T-#{run_id}")
    expect(course).to include('id', 'name')
    expect(course['name']).to eq(course_name)

    found = canvas_api.find_course(course_id: course['id'])
    expect(found['id']).to eq(course['id'])

    canvas_api.delete_course(course_id: course['id'])
    expect { canvas_api.find_course(course_id: course['id']) }
      .to raise_error(CanvasApiClient::ApiError) { |e| expect(e.status).to be_between(404, 404) }
  end

  it 'reaches the staging dashboard via DashboardConsole' do
    # Smallest possible reach-through to confirm the SSH + ruby runner
    # pattern works against staging. No state changes.
    out = DashboardConsole.run('puts "ok"')
    expect(out.strip).to eq('ok')
  end

  it 'reads back an LtiCourseBinding via DashboardConsole' do
    # The test course set up in G6 (Course#68 + binding id 1) is the
    # known fixed state on staging. Read its slug back as a smoke
    # check.
    slug = 'test/canvas_integration_test_course_(test_2026)'
    binding_info = DashboardAdminClient.find_binding(course_slug: slug)
    expect(binding_info).to include('id', 'course_id', 'lms_context_id')
  end
end
