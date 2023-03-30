source 'https://rubygems.org'
ruby '>= 3.1.2'

### Basic Framework
gem 'rails', '7.0.4'
gem 'jbuilder' # DSL for building JSON view templates
gem 'haml-rails' # HTML template language, used instead of ERB
gem 'bootsnap', require: false # Makes rails boot faster via caching
gem 'faker', require: false # Generates random data for example records
gem 'figaro' # easy access to ENV variables. Deprecated.
gem 'puma'

### Database and caching
gem 'mysql2' # MariaDB integration for ActiveRecord
gem 'activerecord-import' # Used to save batches of new ActiveRecord objects
# convenient cloning of ActiveRecord objects along with child records
# Used for cloning surveys and courses.
gem 'deep_cloneable'
gem 'paper_trail' # Save histories of record changes related to surveys
gem "kt-paperclip" # used by Course and UserProfile for file attachments.
gem 'sidekiq' # Framework for running background worker jobs
gem 'sidekiq-unique-jobs' # Plugin to prevent duplicate jobs in the sidekiq queue
gem 'sidekiq-cron' # Plugin for cron-style recurring jobs in Sidekiq
gem 'dalli' # Caching
gem 'connection_pool'
gem 'fuzzily_reloaded' # fuzzy search for ActiveRecord tables

### Login, authentication, browser support
gem 'devise' # user session management
# Login via MediaWiki OAuth. This fork adds features to support account creation flow.
gem 'omniauth-mediawiki', git: 'https://github.com/ragesoss/omniauth-mediawiki.git'
gem "omniauth-rails_csrf_protection" # Makes Rails work with Omniauth 2
# Parses user agent strings to determine which browser is in use.
# Used for browser support warnings.
gem 'browser'

### Email
gem 'validates_email_format_of' # Email format validation, used in User model
gem 'premailer-rails' # used for enabling CSS for mailer emails
gem 'nokogiri' # expected by premailer-rails but not required
gem 'mailgun-ruby' # email sending service

### Incoming Mail
gem 'griddler'
gem 'griddler-mailgun'

### Survey and Ticketing features, implemented as a rails engines
# If you want to be able to hack locally on rapidfire or ticket_dispenser, use `path:` instead of `git:`.
gem 'ticket_dispenser', git: 'https://github.com/WikiEducationFoundation/TicketDispenser.git'
# gem 'ticket_dispenser', path: '../TicketDispenser'
gem 'rapidfire', git: 'https://github.com/WikiEducationFoundation/rapidfire', branch: 'master'
# gem 'rapidfire', path: './vendor/rapidfire'

### HTTP and API tools
gem 'faraday' # Standard HTTP library
gem 'mediawiki_api', git: 'https://github.com/ragesoss/mediawiki-ruby-api', branch: 'master' # Library for querying mediawiki API
gem 'restforce' # Salesforce API access
gem 'oj' # JSON Parsing library
gem 'rss' # Standard RSS library

### Internationalization
gem 'http_accept_language'
gem 'i18n-js'

### Analytics and error monitoring
gem 'sentry-ruby' # error reporting for both server-side Ruby and client-side JS
gem 'sentry-rails' # Sentry extension for Rails
gem 'sentry-sidekiq' # Sentry extension for Sidekiq
gem 'piwik_analytics', git: 'https://github.com/ragesoss/piwik-ruby-tracking' # traffic analytics
gem 'newrelic_rpm' # performance monitoring

### Assorted conveniences and tools
gem 'breadcrumbs_on_rails' # Used for breadcrumb navigation on training pages
gem 'redcarpet' # Markdown parser, used sparingly in haml templates and helpers
gem 'hashugar' # Users to make yaml/json based training objects easy to access
gem 'simple_form' # Alternative to basic rails form helpers
gem 'acts_as_list' # ActiveRecord plugin for ordered records, used in SurveysQuestionGroups
gem 'sentimental' # Used sparingly for sentiment analysis of Survey results
gem 'will_paginate' # Used for pagination for Campaign Articles
gem 'chartkick' # Used for plots in Rails views
gem 'rack-cors', require: 'rack/cors' # Used for allowing cross-domain requests
### System utilities
gem 'pandoc-ruby' # Text converter, for markdown<->html<->wikitext conversions

### Platform-specific fixes
# You might need to uncomment these on Windows if you aren't using WSL.

# TZ information is not available on Windows, needs to be installed separately
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw]

# for those who don't have a native readline utility installed
# gem 'rb-readline', platforms: [:mingw, :mswin, :x64_mingw]

### Performance
gem 'rack-mini-profiler'
gem 'stackprof'

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
  gem 'openssl', '~> 3'
  gem 'x25519' # workaround for openssl bug: https://github.com/ruby/openssl/issues/489
  gem 'rails-erd' # Generates`erd.pdf`
  gem 'annotate' # Generates automatic schema notations on model files
  gem 'memory_profiler' # Unsafe for production use
end

group :development, :test do
  gem 'pry-rails'
  gem 'byebug'
  gem 'rspec-rails'
  gem 'rubocop',  require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-performance', require: false
  gem 'factory_bot_rails' # Factory for creating ActiveRecord objects in tests
  gem 'rack-proxy', '~> 0.7.6'
end

group :test do
  gem 'rake', '>= 11.0'
  gem 'capybara'
  gem 'capybara-screenshot'
  gem 'webdrivers' # automatable browser drivers used by Capybara
  gem 'webmock'
  gem 'vcr' # Saves external web requests and replays them in tests
  gem 'simplecov', require: false
  gem 'shoulda-matchers'
  gem 'rails-controller-testing'
end
