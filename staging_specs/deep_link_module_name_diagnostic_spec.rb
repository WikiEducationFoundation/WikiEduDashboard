# frozen_string_literal: true

require 'cgi'
require 'uri'
require_relative 'spec_helper'

# DIAGNOSTIC (not a regression spec): does LTIAAS pass Canvas's
# `https://canvas.instructure.com/lti/module_name` claim through into the
# signed DeepLinkingResponse JWT?
#
# Background: a bulk deep-link import creates a Canvas module, and Canvas
# names it from that claim (falling back to "New Content From App"). We send
# the claim on every deep-linking response — BuildLtiDeepLinkForm — but
# LTIAAS was dropping it (confirmed 2026-07-24 by decoding the returned JWT;
# LTIAAS acknowledged and shipped a hotfix).
#
# ANSWERED 2026-07-25: the claim is now PRESENT in the signed JWT, at both
# two and nine content items, with our retry-without-the-claim fallback never
# firing — LTIAAS's hotfix works. Imports on `canvas.wikiedu.org` nonetheless
# still produce "New Content From App", which places the remaining gap in
# Canvas: it only reads this claim as of canvas-lms 8565b537 (2026-04-09,
# no feature flag), and that instance is self-hosted. Keep this spec for
# re-checking after a Canvas upgrade, or against another institution's Canvas.
#
# Cheap by design: no provisioning. It reuses an existing bound staging
# course, opens the real Modules-page picker to obtain a live ltik, then
# builds the deep-linking form through the production code path
# (BuildLtiDeepLinkForm on the staging app, via DashboardConsole) and decodes
# what comes back. Nothing is submitted to Canvas, so no course state
# changes.
#
# Verdict is printed, not asserted — this answers a question about a third
# party's behavior, so a red spec would be noise in the suite.
describe 'DIAGNOSTIC: does LTIAAS pass module_name through', :staging do
  let(:required_env) do
    %w[CANVAS_ADMIN_TOKEN CANVAS_TEST_ACCOUNT_ID
       CANVAS_TEST_INSTRUCTOR_LOGIN CANVAS_TEST_INSTRUCTOR_PASSWORD]
  end
  let(:canvas_api) { CanvasApiClient.new }
  let(:module_name_claim) { 'https://canvas.instructure.com/lti/module_name' }

  before do
    missing = required_env.select { |k| ENV[k].to_s.empty? }
    skip("missing env vars: #{missing.join(', ')}") if missing.any?
  end

  it 'reports whether the claim reaches the signed DeepLinkingResponse' do
    binding_row = bound_binding
    skip 'no bound staging binding to launch from' if binding_row.nil?

    canvas_course_id = canvas_course_id_for(binding_row['lms_context_id'])
    ltik = capture_picker_ltik(canvas_course_id)
    expect(ltik.to_s).not_to be_empty

    # Two shapes against one ltik: a small selection, then everything — the
    # real Modules import is the latter.
    [2, nil].each do |count|
      report(decode_deep_linking_response(ltik, binding_row['id'], count:))
    end
  end

  private

  # Any binding that has a Dashboard course — the picker only offers
  # gradables for a linked course.
  def bound_binding
    DashboardConsole.run_json(<<~RUBY)
      require 'json'
      b = LtiCourseBinding.where.not(course_id: nil).order(:id).last
      puts((b ? b.attributes.slice('id', 'lms_context_id') : nil).to_json)
    RUBY
  end

  # Canvas resolves its own numeric course id from the opaque LTI context id
  # via the `lti_context_id:` lookup prefix.
  def canvas_course_id_for(lms_context_id)
    canvas_api.find_course(course_id: "lti_context_id:#{lms_context_id}")['id']
  end

  # Open the real Modules-page import modal and read the launch's ltik out of
  # the picker's own URL. That ltik authenticates the LTIAAS calls below,
  # exactly as it would on a real import.
  #
  # From the frame's URL rather than the picker's hidden `ltik` field: the
  # field only exists when there is something left to import, and a course
  # whose columns are already imported renders the "all added" branch instead.
  # Selenium's current_url reports the top-level document, so ask the frame.
  def capture_picker_ltik(canvas_course_id)
    in_canvas do
      ensure_canvas_logged_in_as_instructor
      visit "/courses/#{canvas_course_id}/modules"
      open_modules_tool_modal
      within_frame(find(LaunchHelpers::DIALOG_IFRAME, match: :first, wait: 20)) do
        expect(page).to have_content('Import Wikipedia assignments', wait: 20)
        frame_url = page.evaluate_script('window.location.href')
        CGI.parse(URI.parse(frame_url).query.to_s)['ltik'].first
      end
    end
  end

  # Build the deep-linking form on staging through the production service, so
  # the request body is byte-identical to a real import, then decode the JWT
  # LTIAAS signed back to us.
  # `count` mirrors how many columns the instructor is importing: the real
  # Modules-page flow sends every gradable at once (nine on a full timeline),
  # so a claim that survives a two-item request proves less than it looks.
  # Also reports whether BuildLtiDeepLinkForm's rescue fired — that retry
  # deliberately re-sends *without* the claim, which would leave the module
  # unnamed for a reason that has nothing to do with LTIAAS dropping it.
  def decode_deep_linking_response(ltik, binding_id, count: nil)
    DashboardConsole.run_json(<<~RUBY)
      require 'json'
      require 'base64'
      binding = LtiCourseBinding.find(#{binding_id})
      gradables = DeepLinkableGradables.new(binding.course).result
      gradables = gradables.first(#{count}) if #{count.inspect}
      client = LtiaasClient.with_ltik(ENV['LTIAAS_DOMAIN'], ENV['LTIAAS_API_KEY'],
                                      #{ltik.inspect})
      items = gradables.map do |g|
        { type: 'ltiResourceLink',
          url: "https://" + ENV['LTIAAS_DOMAIN'] + "/lti/launch?resource=" + CGI.escape(g.resource),
          title: g.label, custom: { resource: g.resource },
          lineItem: { scoreMaximum: 1.0, label: g.label, tag: g.resource } }
      end
      body = { contentItems: items,
               'https://canvas.instructure.com/lti/module_name' =>
                 I18n.t('lti.deep_link.module_name') }
      result = { sent_items: items.length, retry_fired: false, error: nil }
      begin
        form = client.post('/api/deeplinking/form', body)['form']
      rescue StandardError => e
        result[:retry_fired] = true
        result[:error] = e.class.name + ': ' + e.message.to_s[0, 300]
        form = client.post('/api/deeplinking/form', { contentItems: items })['form']
      end
      jwt = form[/name=.JWT. value=.([^"']+)./, 1]
      payload = jwt.split('.')[1]
      payload += '=' * ((4 - (payload.length % 4)) % 4)
      result[:jwt] = JSON.parse(Base64.urlsafe_decode64(payload))
      puts result.to_json
    RUBY
  end

  def report(result)
    payload = result['jwt']
    claim = payload[module_name_claim]
    items = payload['https://purl.imsglobal.org/spec/lti-dl/claim/content_items']
    warn "\n  [module_name diagnostic] items sent: #{result['sent_items']}"
    warn "  our retry-without-claim fired: #{result['retry_fired']} #{result['error']}"
    warn "  JWT claims: #{payload.keys.sort.join(', ')}"
    warn "  content items returned: #{items&.length.inspect}"
    warn "  module_name claim: #{claim.inspect}"
    warn(if claim.to_s.empty?
           '  VERDICT: ABSENT — LTIAAS is still dropping the claim. Send this ' \
           'claim list to LTIAAS.'
         else
           '  VERDICT: PRESENT — LTIAAS passes it through; a still-unnamed ' \
           'module is then Canvas-side.'
         end)
  end
end
