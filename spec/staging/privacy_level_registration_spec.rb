# frozen_string_literal: true

require_relative 'spec_helper'

# Verifies the one thing the guide now depends on: that appending
# `?privacy_level=anonymous` to the LTIAAS registration URL puts `anonymous` on
# the **installed tool**, not just on the developer key's configuration.
#
# Why that distinction is the whole point: registering by hand and choosing
# **Anonymized** in Canvas's Register App dialog left `anonymous` on the key and
# the installed tool `public` — twice, tool 5 in February and tool 9 on
# 2026-07-27 — so NRPS returned names and emails for every member. The Dashboard
# discards them (`LtiServiceSession#normalize_member`), but they were being sent,
# and the guide told admins that choosing Anonymized prevented it. LTIAAS's answer
# is the URL parameter, which moves the decision out of that dialog. This spec is
# what stops us taking their word for it.
#
#   bin/staging-feature-spec spec/staging/privacy_level_registration_spec.rb
#
# ## Why this creates a *second* registration rather than redoing the first
#
# LTIAAS refuses to register a platform it already has. The existing staging
# registration is load-bearing — the developer key, its AGS line items, the demo
# course's bindings, and every screenshot gallery hang off it — so a spec that
# deleted it to get a clean run would cost all of that each time.
#
# Instead this registers a second time against the same Canvas. In LTI 1.3 a
# platform is identified by (issuer, client_id), and dynamic registration mints a
# new client_id, so this *may* be accepted even though the issuer is already
# known. Whether LTIAAS keys on the pair or on the issuer alone is not documented
# and has not been observed — so this spec is also the experiment that settles it.
#
# If LTIAAS refuses, the spec fails at the registration dialog with its error
# visible, and the fallback is a deliberate teardown-and-re-register run
# (`docs/canvas_dev_setup.md` §0) accepting that staging needs re-provisioning
# afterwards. A refusal here is information, not a flake — read the failure.
#
# ## Guards
#
# Creating a developer key and an account-level tool is real admin mutation on
# canvas.wikiedu.org, so beyond the usual `:staging` tag this needs
# `ALLOW_CANVAS_REGISTRATION=1`. Everything created is torn down in `after`,
# including on failure; the teardown never touches a key or tool it didn't create.
describe 'LTIAAS privacy_level registration parameter', :staging do
  let(:required_env) do
    %w[CANVAS_TEST_ADMIN_LOGIN CANVAS_TEST_ADMIN_PASSWORD CANVAS_TEST_ACCOUNT_ID
       CANVAS_ADMIN_TOKEN LTIAAS_REGISTRATION_URL]
  end
  let(:account_id) { ENV.fetch('CANVAS_TEST_ACCOUNT_ID', '1') }
  let(:canvas_api) { CanvasApiClient.new }

  # The URL under test. Defaults to the parameter the guide now publishes.
  let(:registration_url) do
    base = ENV.fetch('LTIAAS_REGISTRATION_URL')
    base.include?('privacy_level') ? base : "#{base}?privacy_level=anonymous"
  end

  # Keys and tools that existed before this run. Anything outside these sets is
  # ours and gets removed; anything inside is left strictly alone.
  let(:preexisting_key_ids) { canvas_api.list_developer_keys.map { |k| k['id'].to_s }.to_set }
  let(:preexisting_tool_ids) { canvas_api.list_external_tools.map { |t| t['id'].to_s }.to_set }

  before do
    missing = required_env.select { |k| ENV[k].to_s.empty? }
    skip("missing env vars: #{missing.join(', ')}") if missing.any?
    unless ENV['ALLOW_CANVAS_REGISTRATION'] == '1'
      skip('creates a real Canvas developer key + installed tool; ' \
           'set ALLOW_CANVAS_REGISTRATION=1 to allow it')
    end
    # Force the sets to be captured before anything is created.
    preexisting_key_ids
    preexisting_tool_ids
  end

  after do
    next unless ENV['ALLOW_CANVAS_REGISTRATION'] == '1'

    remove_tools_created_by_this_run
    remove_keys_created_by_this_run
  end

  it 'puts anonymous on the installed tool, not just the developer key' do
    in_admin_browser do
      in_canvas do
        ensure_canvas_logged_in_as_admin
        register_via_dynamic_registration
      end
    end

    key_id = newly_created_key_id
    expect(key_id).not_to be_nil, 'dynamic registration created no new developer key'

    tool_id = newly_created_tool_id
    expect(tool_id).not_to be_nil, <<~MSG
      A developer key was created but no account-level external tool was.
      Registering is not installing — see docs/canvas_integration_guide.md.
    MSG

    # Both sides, and the installed tool is the one that matters.
    expect(canvas_api.developer_key_privacy_level(key_id)).to eq('anonymous')
    expect(canvas_api.external_tool_privacy_level(tool_id)).to eq('anonymous')
  end

  private

  # Canvas's dynamic-registration flow: paste the URL, let Canvas and LTIAAS
  # exchange configuration, then accept. The button labels are Canvas's and have
  # moved between versions, so each step matches on any of the labels seen —
  # a failure here should read as "the dialog changed", not as a privacy result.
  def register_via_dynamic_registration
    visit "/accounts/#{account_id}/developer_keys"
    click_any_button(['+ Developer Key', 'Developer Key'])
    click_any_button(['+ LTI Registration', 'LTI Registration'])
    fill_in_registration_url
    click_any_button(%w[Continue Next])
    accept_registration_dialog
  end

  def fill_in_registration_url
    field = eventually(attempts: 8, interval: 2) do
      first(:fillable_field, type: 'url', minimum: 0) || first(:fillable_field, minimum: 0)
    end
    raise 'no URL field in the LTI registration dialog' if field.nil?

    field.set(registration_url)
  end

  # The dialog ends in a review step whose final action has been labelled
  # "Enable & Close", "Install", and "Enable" across Canvas versions. LTIAAS
  # refusing the registration surfaces here, so the wait is generous and the
  # failure deliberately carries the page text.
  def accept_registration_dialog
    click_any_button(['Enable & Close', 'Install', 'Enable', 'Close'], attempts: 30)
    expect(page).to have_no_button('Enable & Close', wait: 30)
  end

  # Clicks whichever of `labels` appears first, polling until one does.
  # Deliberately not `first(:button, label, wait:, minimum: 0)`: `minimum: 0` is
  # satisfied by zero matches, so Capybara returns immediately and never waits.
  def click_any_button(labels, attempts: 10)
    button = eventually(attempts:, interval: 2) do
      labels.filter_map { |label| first(:button, label, minimum: 0) }.first
    end
    raise button_absence_message(labels) if button.nil?

    button.click
  end

  def button_absence_message(labels)
    "none of these buttons appeared: #{labels.join(', ')}\n" \
      "page said: #{page.text.to_s[0, 800]}"
  end

  def newly_created_key_id
    canvas_api.list_developer_keys
              .map { |k| k['id'].to_s }
              .find { |id| !preexisting_key_ids.include?(id) }
  end

  def newly_created_tool_id
    canvas_api.list_external_tools
              .map { |t| t['id'].to_s }
              .find { |id| !preexisting_tool_ids.include?(id) }
  end

  # Tools first: an installed tool belongs to a key, and Canvas is happier
  # removing it before the key goes. Failures are reported, never raised — a
  # teardown problem shouldn't mask the result, but it must not be silent either,
  # since the leftovers need removing by hand.
  def remove_tools_created_by_this_run
    ids = canvas_api.list_external_tools.map { |t| t['id'].to_s } - preexisting_tool_ids.to_a
    ids.each { |id| attempt_removal("external tool #{id}") { canvas_api.delete_external_tool(id) } }
  end

  def remove_keys_created_by_this_run
    ids = canvas_api.list_developer_keys.map { |k| k['id'].to_s } - preexisting_key_ids.to_a
    ids.each { |id| attempt_removal("developer key #{id}") { canvas_api.delete_developer_key(id) } }
  end

  def attempt_removal(what)
    yield
    warn "[teardown] removed #{what}"
  rescue StandardError => e
    warn "[teardown] FAILED to remove #{what} (#{e.class}: #{e.message}) — remove it by hand"
  end
end
