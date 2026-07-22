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
  let(:tool_name)      { 'wikiedu.org testing' }
  let(:account_id)     { ENV.fetch('CANVAS_TEST_ACCOUNT_ID', '1') }
  let(:screenshot_dir) { canvas_shots_dir('admin') }

  before do
    missing = required_env.select { |k| ENV[k].to_s.empty? }
    skip("missing env vars: #{missing.join(', ')}") if missing.any?
  end

  it 'captures the developer key, its LTI config, and the account app' do
    in_canvas do
      ensure_canvas_logged_in_as_instructor # same Canvas user as CANVAS_ADMIN_TOKEN

      visit "/accounts/#{account_id}/developer_keys"
      expect(page).to have_content(tool_name, wait: 20)
      capture('a01-developer-keys')

      # Open the key's LTI config (read-only: capture, then navigate away without
      # saving). Two shots: the registration overview, and the scopes/placements
      # (a tab on dynamic-registration keys; a scroll on manual ones).
      open_developer_key_config
      capture('a02-developer-key-config')
      show_scopes_and_placements
      capture('a03-developer-key-scopes-placements')

      # Canvas moved LTI tool management to the "Apps" (Canvas Apps) page —
      # installed tools are under the "Manage" tab.
      visit "/accounts/#{account_id}/apps"
      # "Manage" is an InstUI role=tab element, not a link/button.
      find('[role="tab"]', text: 'Manage', wait: 15).click
      expect(page).to have_content(tool_name, wait: 20)
      capture('a04-canvas-apps-manage')
    end
  end

  # Open the LTI 1.3 key's config from its row (edit pencil — an <a> on
  # dynamic-registration keys, a <button> on manual ones; the stable id
  # prefix covers both). Read-only — we navigate away without saving.
  def open_developer_key_config
    row = find(:xpath, "//*[normalize-space()='#{tool_name}']/ancestor::tr[1]", wait: 20)
    within(row) { find('[id^="edit-developer-key-button"]').click }
    # Dynamic-registration keys land on a "<tool> Settings" page (Permissions,
    # anonymized data-sharing, Placements); manual keys open the config tray.
    expect(page).to have_text(/Permissions|Placements|Redirect URIs/, wait: 30)
    sleep 2 # let the page/tray finish rendering before capturing
  end

  # Dynamic-registration settings pages put per-placement config under a
  # "Placements" heading; manual-key trays under "LTI Advantage Services".
  def show_scopes_and_placements
    scroll_config_to('Placements')
  rescue Capybara::ElementNotFound
    scroll_config_to('LTI Advantage Services')
  end

  # Scroll a section of the config tray to the top of view (scrolls the tray's
  # own scroll container).
  def scroll_config_to(heading)
    el = find(:xpath, "//*[contains(text(), '#{heading}')]", match: :first, wait: 15)
    page.execute_script('arguments[0].scrollIntoView({ block: "start" })', el)
    sleep 1
  end

  def capture(name)
    save_screenshot_to(screenshot_dir, name)
  end
end
