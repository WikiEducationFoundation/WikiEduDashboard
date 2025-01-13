ENV['default_course_type'] = 'ClassroomProgramCourse'
ENV['course_prefix'] = 'Wikipedia:Wiki_Ed'
ENV['wiki_language'] = 'en'
ENV['wiki_education'] = 'true'
ENV['disable_wiki_output'] = 'false'
ENV['oauth_ids'] = '542'
ENV['training_page_id'] = '36892501'
ENV['training_path'] = 'training_content/wiki_ed'
ENV['training_slides_wiki_page'] = 'Training modules/dashboard/slides-test'
ENV['training_modules_wiki_page'] = 'Training modules/dashboard/modules-test'
ENV['training_libraries_wiki_page'] = 'Training modules/dashboard/libraries-test'
ENV['default_campaign'] = 'spring_2015'
ENV['campaigns'] = 'fall_2014,spring_2015'
ENV['campaign_fall_2014'] = 'Wikipedia:Education_program/Dashboard/Fall_2014_course_ids'
ENV['campaign_spring_2015'] = 'Wikipedia:Education_program/Dashboard/course_ids'
ENV['sentry_dsn'] = ''
ENV['no_views'] = 'false'
#ENV['hot_loading'] = 'false'
ENV['mailgun_key'] = 'mailgun_api_key'
ENV['enable_legacy_courses'] = 'true'
ENV['training_path'] = 'training_content/wiki_ed'
ENV['SF_SERVER'] = 'https://cs54.salesforce.com/'
ENV['edit_en.wikipedia.org'] = 'true'
ENV['dashboard_url'] = 'dashboard.wikiedu.org'
ENV['TICKET_FORWARDING_DOMAIN'] = 'wikiedu.org'
ENV['SALESFORCE_BCC_EMAIL'] = 'salesforce@salesforce.com'
ENV['ENABLE_ADVANCED_FEATURES'] = 'true'
ENV['test_user'] = 'Ragetest dashboard-test-suite'
ENV['test_user_password'] = 'testpassword'
# https://meta.wikimedia.org/wiki/Special:OAuthListConsumers/view/b56122b2abe01f163349c9d0a6bcded5
ENV['wikipedia_token'] = 'b56122b2abe01f163349c9d0a6bcded5'
ENV['wikipedia_secret'] = '507c74d4c4cb6015c9087b2decb80d82b96b905e'
ENV['WikimediaCampaignsPlatformSecret'] = 'SharedSecret'
ENV['blocked_assignment_category'] = 'testcategory'

FileUtils.mkdir_p(".nyc_output")
Dir.glob("./.nyc_output/*").each{ |f| FileUtils.rm(f) }

def dump_js_coverage
  return unless ENV["COVERAGE"]

  page_coverage = page.evaluate_script("JSON.stringify(window.__coverage__);")
  return if page_coverage.blank?

  File.open(Rails.root.join(".nyc_output", "temp.json"), "w") do |report|
    report.puts page_coverage
  end

  system("npx nyc merge .nyc_output .nyc_output/out.json >> /dev/null && rm .nyc_output/temp.json")
end


Rails.application.configure do
  # Settings specified here will take
  # precedence over those in config/application.rb.
  Paperclip.options[:command_path] = "/usr/bin"
  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure static asset server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = { 'Cache-Control' => 'public, max-age=3600' }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.default_url_options = { host: "localhost:3000" }
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations
  config.i18n.raise_on_missing_translations = true

  config.allow_concurrency = false

  config.log_level = :warn
  
end
