# frozen_string_literal: true

require 'fileutils'
require_relative 'spec_helper'

# DIAGNOSTIC (not a regression spec): answers the gating question for the
# Canvas deep-linking pivot — does a launch of a *deep-link-created*
# resource link actually deliver `services.assignmentAndGrades.lineItemId`
# (and does our `resource` marker survive)?
#
# Background: SyncLtiLineItems' auto-created, course-level line items (no
# resourceLinkId) produce launches with no custom claim and no lineItemId,
# so the assignment_view drill-down can't tell which column was clicked
# (see .claude/canvas_integration/assignment_view_deep_linking_decision-
# 2026-05-29.md). Deep linking is the proposed fix. Before building the
# full per-assignment picker, this probe confirms the plumbing: the minimal
# LtiLaunchController#deep_link / BuildLtiDeepLinkForm stub returns one
# synthetic content item with a `lineItem`; if Canvas then creates an
# assignment whose launch carries lineItemId, deep linking is viable.
#
# Verdict is read two ways:
#   1. Behavioral (automated): on the resource-link launch, lineItemId
#      makes LtiLaunchController#assignment_launch? fire, rendering the
#      assignment_view — which, with no matching local LtiLineItem, falls
#      to assignment_view_orphan ("There is no Dashboard content to show
#      for this assignment."). Seeing that = lineItemId PRESENT. Falling
#      through to the instructor setup view ("Set up the Wiki Education
#      Dashboard") = lineItemId ABSENT.
#   2. Definitive (manual): with LTI_LAUNCH_DEBUG=1 set on the staging web
#      app, LtiLaunchController#log_launch_claims emits a `[LTI launch]`
#      WARN line carrying the AGS keys + lineItemId value and the full
#      custom object. Grep the staging Apache error log for it after the
#      run (see the printed reminder).
#
# Provisions a fresh Canvas course, drives the instructor through Canvas's
# deep-linking assignment-creation modal against our tool, launches the
# resulting assignment, reports + screenshots the verdict. Tears the Canvas
# course down on completion. No Dashboard course / binding is needed: the
# probe stub ignores them.
describe 'DIAGNOSTIC: deep-link resource link delivers lineItemId', :staging do
  let(:required_env) do
    %w[
      CANVAS_ADMIN_TOKEN CANVAS_TEST_ACCOUNT_ID
      CANVAS_TEST_INSTRUCTOR_USER_ID
      CANVAS_TEST_INSTRUCTOR_LOGIN CANVAS_TEST_INSTRUCTOR_PASSWORD
      WIKIPEDIA_TEST_INSTRUCTOR_USERNAME WIKIPEDIA_TEST_INSTRUCTOR_PASSWORD
    ]
  end

  # The title BuildLtiDeepLinkForm puts on the probe content item; Canvas
  # uses it as the created assignment's name.
  let(:probe_assignment_name) { 'WED deep-link probe' }

  let(:run_id)             { Time.now.strftime('%Y%m%d%H%M%S') }
  let(:canvas_course_name) { "Staging DL-diag #{run_id}" }
  let(:canvas_api)         { CanvasApiClient.new }
  let(:provisioned)        { @provisioned ||= {} }
  let(:artifact_dir)       { File.expand_path('../../tmp/staging-diagnostics', __dir__) }

  before do
    missing = required_env.select { |k| ENV[k].to_s.empty? }
    skip("missing env vars: #{missing.join(', ')}") if missing.any?

    canvas_course = canvas_api.create_course(name: canvas_course_name, course_code: "DLD-#{run_id}")
    provisioned[:canvas_course_id] = canvas_course['id']
    canvas_api.enroll_user(course_id: canvas_course['id'],
                           user_id: ENV.fetch('CANVAS_TEST_INSTRUCTOR_USER_ID'),
                           role: 'TeacherEnrollment')
  end

  after do
    if provisioned[:canvas_course_id]
      DashboardAdminClient.delete_bindings_for(context_title: canvas_course_name)
      canvas_api.delete_course(course_id: provisioned[:canvas_course_id])
    end
  end

  it 'reports whether a deep-link-created assignment launch carries lineItemId' do
    course_id = provisioned[:canvas_course_id]
    create_deep_linked_assignment_via_tool(course_id)

    assignment = eventually do
      canvas_api.find_assignment(course_id:, name: probe_assignment_name)
    end
    expect(assignment).not_to(be_nil,
                              'deep-linking modal did not create the probe assignment — ' \
                              'the content-item submission step likely needs selector tweaks')
    warn "  [diag] probe assignment: id=#{assignment['id']} " \
         "submission_types=#{assignment['submission_types'].inspect}"

    verdict = launch_assignment_and_read_verdict(course_id, assignment['id'])
    capture_page('deep_link_lineitem_launch.png')
    warn "  [diag] VERDICT: lineItemId on the resource-link launch => #{verdict}"
    warn '  [diag] For the definitive read, grep the staging Apache error log for ' \
         '"[LTI launch]" (requires LTI_LAUNCH_DEBUG=1 on the web app).'
  end

  # Drive Canvas's stock new-assignment editor through the External Tool /
  # deep-linking flow against our tool. Selectors are best-guess for
  # Canvas's stock UI (same caveat as launch_helpers); the first real run
  # may need them tweaked, and the modal is the most likely suspect. If
  # automation here proves brittle, this one step can be performed by hand
  # (create an External Tool assignment, pick "Wiki Education", let the
  # iframe auto-submit, save) and the rest of the spec re-run from the
  # `find_assignment` step.
  def create_deep_linked_assignment_via_tool(course_id)
    in_canvas do
      ensure_canvas_logged_in_as_instructor
      visit "/courses/#{course_id}/assignments/new"
      select 'External Tool', from: 'Submission Type'
      click_button 'Find'
      select_probe_resource_in_modal
      fill_in 'assignment_name', with: probe_assignment_name
      fill_in 'assignment_points_possible', with: '1'
      # Publish (not just Save) so the gradebook column + AGS line item are
      # live; `.save_button` is the hidden legacy control, `.save_and_publish`
      # is the visible one in the modern action-buttons footer.
      find('.save_and_publish').click
    end
    dismiss_consent_banner
  end

  # Inside Canvas's External Tool "Find" dialog (#context_external_tools_select,
  # a list of `ul.tools li.tool a.name` links), click our tool. On staging the
  # tool is the dev key named "wikiedu.org testing". Clicking it fires the
  # assignment_selection deep-linking launch (LTIAAS forwards it to our
  # /lti/deep_link); the returned content item is staged into the dialog's
  # hidden fields — confirmed on staging: #external_tool_create_line_item gets
  # our lineItem and #external_tool_create_custom_params gets {resource:probe}.
  # We then click the dialog's Select button (.add_item_button) to apply the
  # content item to the assignment and close the dialog.
  def select_probe_resource_in_modal
    within('#context_external_tools_select') do
      click_link 'wikiedu.org testing'
    end
    # The hidden line_item field is staged from the deep-linking response.
    # (have_field with a regex `with:` on a hidden input is unreliable, so
    # poll the value directly.) The field is always in the DOM, so find
    # won't raise while we wait for it to populate.
    staged = eventually(attempts: 30, interval: 1) do
      value = find('#external_tool_create_line_item', visible: false).value.to_s
      value.include?('WED deep-link probe')
    end
    expect(staged).to be_truthy
    find('.add_item_button', text: 'Select').click
    expect(page).to have_no_css('.add_item_button', wait: 15)
  end

  # Open the created assignment as the instructor; the resource-link launch
  # fires our tool. Break out of the Canvas iframe + Wikipedia OAuth (silent
  # once the profile is bootstrapped), then read which dashboard view we
  # land on. Returns 'PRESENT', 'ABSENT', or 'UNDETERMINED'.
  def launch_assignment_and_read_verdict(course_id, assignment_id)
    in_canvas do
      visit "/courses/#{course_id}/assignments/#{assignment_id}"
      break_out_of_canvas_iframe(role: :instructor, iframe: canvas_assignment_iframe_locator)
    end
    dismiss_consent_banner
    return 'PRESENT' if page.has_text?('There is no Dashboard content to show', wait: 20)
    return 'ABSENT' if page.has_text?('Set up the Wiki Education Dashboard', wait: 5)

    'UNDETERMINED'
  end

  def capture_page(filename)
    FileUtils.mkdir_p(artifact_dir)
    path = File.join(artifact_dir, filename)
    page.save_screenshot(path)
    warn "  [diag] screenshot: #{path}"
  end
end
