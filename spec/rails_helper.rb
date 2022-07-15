# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
# Load spec_helper before rails, so that simplecov works properly.
require 'spec_helper'
require File.expand_path('../config/environment', __dir__)
require 'rspec/rails'

# Add additional requires below this line. Rails is not loaded until this point!
require 'capybara/rails'
require 'capybara/rspec'
require 'capybara-screenshot/rspec'

Capybara.register_driver :selenium do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities
                 .chrome(chromeOptions: { w3c: false })
  options = Selenium::WebDriver::Chrome::Options.new(
    args: %w[headless no-sandbox disable-gpu --window-size=1200,1200]
  )
  Capybara::Selenium::Driver.new(app,
                                 browser: :chrome,
                                 options: options,
                                 clear_local_storage: false, # Persist local storage across tests
                                 desired_capabilities: capabilities)
end

Rails.cache.clear
Capybara::Screenshot.prune_strategy = :keep_last_run
Capybara.save_path = 'tmp/screenshots/'
Capybara.server = :puma, { Silent: true }

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  config.use_transactional_fixtures = true # This enables transactions for all tests
  config.global_fixtures = :all

  config.include Devise::Test::ControllerHelpers, type: :controller
  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  config.include Warden::Test::Helpers
  Warden.test_mode!

  config.before do
    stub_request(:get, 'https://wikiedu.org/feed')
      .with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' })
      .to_return(status: 200, body: '<rss version="2.0" />', headers: {})
    stub_request(:get, /fonts.googleapis.com/)
      .with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' })
      .to_return(status: 200, body: +'@font-face {}', headers: {})
  end

  config.before(:each, type: :feature, js: true) do
    # Make sure any logs from the previous test get
    errors = page.driver.browser.manage.logs.get(:browser)
    warn errors
  end

  # fail on javascript errors in feature specs
  config.after(:each, type: :feature, js: true) do |example|
    dump_js_coverage
    # `Capybara.reset_sessions!` here would ensure that any error
    # logs from this session can be captured now, by closing any open connections.
    # Otherwise, if they show up after the `manage.logs.get` step, they
    # will cause the next spec to fail instead of the one that generated
    # them.
    # Instead, we clear and print any after-success error
    # logs in the `before` block above.
    errors = page.driver.browser.manage.logs.get(:browser)
    # pass `js_error_expected: true` to skip JS error checking
    next if example.metadata[:js_error_expected]

    if errors.present?
      aggregate_failures 'javascript errrors' do
        errors.each do |error|
          # some specs test behavior for 4xx responses and other errors.
          # Don't fail on these.
          next if /Failed to load resource/.match?(error.message)

          warn 'JavaScript warning / error'
          warn error.level
          warn error
          warn error.message
          expect(error.level).not_to eq('SEVERE'), error.message
        end
      end
    end
  end
  config.after(:suite) do
    if ENV['COVERAGE'] == 'true'
      Rails.application.load_tasks
      Rake::Task['generate:coverage'].invoke
    end
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    # Choose a test framework:
    with.test_framework :rspec

    # Choose one or more libraries:
    with.library :active_record
    with.library :active_model
    with.library :action_controller
    # Or, choose the following (which implies all of the above):
    with.library :rails
  end
end

# This lets us switch between Poltergeist and Selenium without changing the spec.
# Some .click actions don't work on Poltergeist because of overlapping elements,
# but .trigger('click') is only available in Poltergeist.
def omniclick(node)
  if Capybara.current_driver == :poltergeist
    node.trigger('click')
  else
    node.click
  end
end

# This is a version of the slug with percent encoding of non-ascii characters.
# It's equivalent to URI.escape(slug), since URI.escape is deprecated.
def escaped_slug(slug)
  URI::RFC2396_Parser.new.escape slug
end

def pass_pending_spec
  if RSpec.configuration.formatter_loader.formatters.first
          .is_a? RSpec::Core::Formatters::DocumentationFormatter
    puts 'PASSED'
  else
    print 'P'
  end
  raise 'this test passed — this time'
end
