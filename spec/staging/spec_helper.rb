# frozen_string_literal: true

# Spec helper for live-staging feature specs. Intentionally does NOT
# require the regular `rails_helper` — these specs drive a real browser
# against the deployed staging environment (`dashboard-testing.wikiedu.org`
# and `canvas.wikiedu.org`) and don't need the local Rails app booted, the
# test DB, transactional fixtures, or WebMock blocking real HTTP.
#
# See `docs/staging_feature_specs.md` for the one-time bootstrap.

require 'capybara/rspec'
require 'selenium-webdriver'

# Persistent Chrome profile. Cookies + Wikipedia OAuth consent + Canvas
# session state all live in this directory and survive between runs, so
# we only have to authenticate interactively on the first bootstrap.
PROFILE_DIR = File.expand_path('../../tmp/staging-browser-profile', __dir__).freeze

# Where screenshots + page sources go on failure.
FAILURE_ARTIFACT_DIR = File.expand_path('../../tmp/staging-failures', __dir__).freeze

# Register the :staging_chrome driver at load time. Registration is
# side-effect-free — it just adds an entry to Capybara's driver
# registry; nothing changes about which driver Capybara actually uses
# until a spec explicitly switches to it.
Capybara.register_driver :staging_chrome do |app|
  args = ["--user-data-dir=#{PROFILE_DIR}", '--window-size=1280,900']
  args.prepend('--headless=new') if ENV['HEADLESS']
  options = Selenium::WebDriver::Chrome::Options.new(args: args)
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options,
                                      clear_session_storage: false,
                                      clear_local_storage: false)
end

# Load support files (in_canvas/in_dashboard helpers, screenshot-on-failure).
Dir[File.join(__dir__, 'support', '*.rb')].each { |f| require f }

# Per-(staging-example) Capybara reconfiguration. Critical: this is
# wrapped in an `around` hook scoped to `:staging` so it ONLY applies
# during a staging example's lifetime. Setting these at file-load
# time globally clobbered the dashboard's regular Capybara config and
# broke every other feature spec in CI when rspec discovered the
# staging files alongside everything else.
STAGING_CAPYBARA_SETTINGS = %i[
  run_server default_driver javascript_driver app_host
  default_max_wait_time save_path
].freeze

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # `:staging` tagged specs are opt-in only — `spec/spec_helper.rb` adds
  # `filter_run_excluding :staging` to the default rspec config, and our
  # `bin/staging-feature-spec` runner passes `--tag staging` to re-enable
  # them. CI never runs them.

  config.include Capybara::DSL, :staging
  config.include StagingSessions, :staging
  config.include LoginHelpers, :staging
  config.include LaunchHelpers, :staging

  config.around(:each, :staging) do |example|
    prior = STAGING_CAPYBARA_SETTINGS.to_h { |k| [k, Capybara.send(k)] }
    Capybara.run_server = false
    Capybara.default_driver = :staging_chrome
    Capybara.javascript_driver = :staging_chrome
    Capybara.app_host = 'https://dashboard-testing.wikiedu.org'
    Capybara.default_max_wait_time = 15
    Capybara.save_path = FAILURE_ARTIFACT_DIR
    example.run
  ensure
    prior&.each { |k, v| Capybara.send("#{k}=", v) }
  end
end
