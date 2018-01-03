ENV['dashboard_url'] = 'dashboard.wikiedu.org'
ENV['default_course_type'] = 'ClassroomProgramCourse'
ENV['open_course_creation'] = 'false'
ENV['disable_wiki_output'] = 'false'
ENV['open_course_creation'] = 'false'
ENV['course_prefix'] = 'Wikipedia:Wiki_Ed'
ENV['wiki_language'] = 'en'
ENV['enable_article_finder'] = 'true'
ENV['oauth_ids'] = '252,212,542'
ENV['training_page_id'] = '36892501'
ENV['training_path'] = 'training_content/wiki_ed'
ENV['default_campaign'] = 'spring_2015'
ENV['campaigns'] = 'fall_2014,spring_2015'
ENV['campaign_fall_2014'] = 'Wikipedia:Education_program/Dashboard/Fall_2014_course_ids'
ENV['campaign_spring_2015'] = 'Wikipedia:Education_program/Dashboard/course_ids'
ENV['sentry_dsn'] = 'dummy://12345:67890@sentry.localdomain/sentry/42'
ENV['sentry_public_dsn'] = 'http://anotherlongkey@sentry.example.com/1'
ENV['no_views'] = 'false'
ENV['disable_onboarding'] = 'false'
#ENV['hot_loading'] = 'false'
ENV['SENDER_EMAIL_ADDRESS'] = 'root@localhost'
ENV['enable_legacy_courses'] = 'true'
ENV['enable_get_help_button'] = 'true'
ENV['enable_language_switcher'] = 'true'
ENV['training_path'] = 'training_content/wiki_ed'
ENV['enable_chat'] = 'true'
ENV['chat_admin_username'] = 'username'
ENV['chat_admin_password'] = 'password'
ENV['chat_server'] = 'https://dashboardchat.wmflabs.org'
ENV['SF_SERVER'] = 'https://cs54.salesforce.com/'
ENV['edit_en.wikipedia.org'] = 'true'

Rails.application.configure do
  # Settings specified here will take
  # precedence over those in config/application.rb.

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
  config.action_view.raise_on_missing_translations = true

  config.allow_concurrency = false
  config.assets.debug = true
end
