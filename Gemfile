source 'https://rubygems.org'
ruby '2.3.1'
gem 'rails', '5.1.4'
gem 'jbuilder', '~> 2.0' # DSL for building JSON view template
gem 'haml-rails' # HTML template language, used instead of ERB

gem 'mediawiki_api', '0.7.1' # Library for querying mediawiki API
gem 'crack' # JSON / XML parsing. Unused?
gem 'figaro' # easy access to ENV variables. Deprecated.
gem 'whenever' # Translates config/schedule.rb into cron jobs during deployment
gem 'mysql2'
gem 'sidekiq' # Framework for running background worker jobs
gem 'sidekiq-unique-jobs' # Plugin to prevent duplicate jobs in the sidekiq queue
gem 'activerecord-import' # Used to save batches of new ActiveRecord objects
gem 'dalli' # Caching
gem 'connection_pool'
gem 'faraday'
gem 'bootsnap', require: false # Makes rails boot faster via caching

gem 'devise' # user session management
# Login via MediaWiki OAuth. This fork adds features to support account creation flow.
gem 'omniauth-mediawiki', git: 'https://github.com/ragesoss/omniauth-mediawiki.git'

# Parses user agent strings to determine which browser is in use.
# Used for browser support warnings.
gem 'browser'
gem 'http_accept_language'
gem 'i18n-js'

gem 'validates_email_format_of'

 # convenient cloning of ActiveRecord objects along with child records
 # Used for cloning surveys and courses.
gem 'deep_cloneable', '~> 2.3.0'

gem 'sentry-raven' # error reporting for both server-side Ruby and client-side JS
gem 'piwik_analytics', git: 'https://github.com/halfdan/piwik-ruby-tracking.git'
gem 'newrelic_rpm' # monitoring, using in Wiki Ed Production mostly

gem 'redcarpet'
gem 'breadcrumbs_on_rails' # Used for breadcrumb navigation on training pages
gem 'hashugar' # Users to make yaml/json based training objects easy to access

gem 'simple_form'

gem 'acts_as_list'

gem 'sentimental' # Used sparingly for sentiment analysis of Survey results

gem 'premailer-rails' # used for enabling CSS for mailer emails
gem 'nokogiri' # expected by premailer-rails but not required

# UNIVERSAL TEXT CONVERTER - FOR MARDOWN TO MEDIAWIKI TEXT
gem 'pandoc-ruby', '~> 1.0.0'



gem 'mailgun_rails' # Plugin for sending mail via mailgun.com. Unused?

gem 'paper_trail' # Save histories of record changes related to surveys

gem "paperclip" # used by Course and UserProfile for file attachments

# TZ information is not available on Windows, needs to be installed separately
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw]

gem 'restforce', git: 'https://github.com/ejholmes/restforce.git'

gem 'rinruby' # R plots!

# If you want to be able to hack locally on rapidfire,
# run `export RAPIDFIREHACKINGMODE=true` in your terminal.
if ENV['RAPIDFIREHACKINGMODE'] == 'true'
  gem 'rapidfire', path: './vendor/rapidfire'
else
  gem 'rapidfire', git: 'https://github.com/WikiEducationFoundation/rapidfire', branch: 'master'
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller', platforms: [:mri_21]
  gem 'guard-bundler'
  gem 'guard-rails'
  gem 'guard-rspec'
  gem 'rb-fchange', require: false
  gem 'rb-fsevent', require: false
  gem 'rb-inotify', require: false
  gem 'capistrano'
  gem 'capistrano-rvm'
  gem 'capistrano-rails'
  gem 'capistrano-bundler'
  gem 'capistrano-passenger'
  gem 'capistrano-sidekiq'
  gem 'rails-erd'
  gem 'annotate', '~> 2.7.1'
end

group :development, :test do
  gem 'pry-rails'
  gem 'byebug'
  gem 'faker'
  gem 'rspec-rails'
  gem 'rubocop', require: false
  gem 'zeus', platforms: :ruby # zeus doesn't work on Windows
  gem 'timecop' # Test utility for setting the time
  gem 'poltergeist' # Capypara feature specs driven by PhantomJS
  gem 'factory_bot_rails' # Factory for creating ActiveRecord objects in tests
  gem 'rb-readline' # for those who don't have a native readline utility installed
end

group :test do
  gem 'rake', '>= 11.0'
  gem 'capybara'
  gem 'capybara-screenshot'
  gem 'database_cleaner'
  gem 'webmock'
  gem 'vcr'
  gem 'simplecov', require: false
  gem 'shoulda-matchers', '~> 3.1'
  gem 'rails-controller-testing'
end

group :production do
  gem 'uglifier'
  gem 'rails_12factor'
end
