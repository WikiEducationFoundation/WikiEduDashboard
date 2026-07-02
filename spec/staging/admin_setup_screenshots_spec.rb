# frozen_string_literal: true

require_relative 'spec_helper'

# Read-only capture of the Canvas admin's view of the installed Wiki Education
# LTI tool on canvas.wikiedu.org — the "Canvas admin setup" surfaces as they
# exist once configured: the LTI 1.3 developer key and the account-level
# external app. This is the first, read-only tranche of the admin flow; the
# full create -> configure -> teardown walk comes later.
#
# Reuses the instructor login: on staging that Canvas user (user 2, "Sage
# Ross") is the same account admin that holds CANVAS_ADMIN_TOKEN, so no extra
# admin credentials are needed. Read-only — it only navigates and screenshots
# the already-configured tool; it never creates, edits, or deletes anything.
#
#   bin/staging-feature-spec spec/staging/admin_setup_screenshots_spec.rb
#
# Output goes to the harvest run dir (`tmp/canvas-ux-screenshots/admin/`,
# override with CANVAS_SHOTS_DIR); `bin/harvest-canvas-screenshots` collects it.
describe 'Canvas admin setup (read-only) screenshots', :staging do
  let(:required_env) do
    %w[CANVAS_TEST_INSTRUCTOR_LOGIN CANVAS_TEST_INSTRUCTOR_PASSWORD CANVAS_TEST_ACCOUNT_ID]
  end

  # The dev key + account external tool are both named this on staging.
  let(:tool_name)      { 'wikiedu.org testing key' }
  let(:account_id)     { ENV.fetch('CANVAS_TEST_ACCOUNT_ID', '1') }
  let(:screenshot_dir) { canvas_shots_dir('admin') }

  before do
    missing = required_env.select { |k| ENV[k].to_s.empty? }
    skip("missing env vars: #{missing.join(', ')}") if missing.any?
  end

  it 'captures the LTI developer key and the account external app' do
    in_canvas do
      ensure_canvas_logged_in_as_instructor # same Canvas user as CANVAS_ADMIN_TOKEN

      visit "/accounts/#{account_id}/developer_keys"
      expect(page).to have_content(tool_name, wait: 20)
      capture('a01-developer-keys')

      # Canvas moved LTI tool management to the "Apps" (Canvas Apps) page —
      # the Developer Keys screen banners this and links "View in Canvas Apps".
      # It opens on the "Discover" (library) tab; installed tools are under
      # "Manage".
      visit "/accounts/#{account_id}/apps"
      # "Manage" is an InstUI role=tab element, not a link/button.
      find('[role="tab"]', text: 'Manage', wait: 15).click
      expect(page).to have_content(tool_name, wait: 20)
      capture('a02-canvas-apps-manage')
    end
  end

  def capture(name)
    save_screenshot_to(screenshot_dir, name)
  end
end
