source 'https://rubygems.org'
ruby '2.7.1'

### Basic Framework
gem 'rails', '6.0.3.2'
gem 'jbuilder' # DSL for building JSON view template
gem 'haml-rails' # HTML template language, used instead of ERB
gem 'bootsnap', require: false # Makes rails boot faster via caching
gem 'figaro' # easy access to ENV variables. Deprecated.

### Database and caching
gem 'mysql2' # MySQL integration for ActiveRecord
gem 'activerecord-import' # Used to save batches of new ActiveRecord objects
# convenient cloning of ActiveRecord objects along with child records
# Used for cloning surveys and courses.
gem 'deep_cloneable'
gem 'paper_trail' # Save histories of record changes related to surveys
gem "paperclip" # used by Course and UserProfile for file attachments
gem 'sidekiq' # Framework for running background worker jobs
gem 'sidekiq-unique-jobs' # Plugin to prevent duplicate jobs in the sidekiq queue
gem 'dalli' # Caching
gem 'connection_pool'
gem 'fuzzily_reloaded' # fuzzy search for ActiveRecord tables

### Login, authentication, browser support
gem 'devise' # user session management
# Login via MediaWiki OAuth. This fork adds features to support account creation flow.
gem 'omniauth-mediawiki', git: 'https://github.com/ragesoss/omniauth-mediawiki.git'
# Parses user agent strings to determine which browser is in use.
# Used for browser support warnings.
gem 'browser'

### Email
gem 'validates_email_format_of' # Email format validation, used in User model
gem 'premailer-rails' # used for enabling CSS for mailer emails
# forked temporarily, pending https://github.com/premailer/premailer/pull/376
gem 'premailer', git: 'https://github.com/premailer/premailer.git', branch: 'master'
gem 'nokogiri' # expected by premailer-rails but not required
gem 'mailgun-ruby' # email sending service

### Survey and Ticketing features, implemented as a rails engines
# If you want to be able to hack locally on rapidfire or ticket_dispenser:

# gem 'ticket_dispenser', path: '../TicketDispenser'
gem 'ticket_dispenser', git: 'https://github.com/WikiEducationFoundation/TicketDispenser.git'
# gem 'rapidfire', path: './vendor/rapidfire'
gem 'rapidfire', git: 'https://github.com/WikiEducationFoundation/rapidfire', branch: 'master'

### HTTP and API tools
gem 'faraday' # Standard HTTP library
gem 'mediawiki_api', '0.7.1' # Library for querying mediawiki API
gem 'restforce' # Salesforce API access
gem 'oj' # JSON Parsing library

### Internationalization
gem 'http_accept_language'
gem 'i18n-js'

### Deployment
gem 'whenever' # Translates config/schedule.rb into cron jobs during deployment

### Analytics and error monitoring
gem 'sentry-raven' # error reporting for both server-side Ruby and client-side JS
gem 'piwik_analytics', git: 'https://github.com/halfdan/piwik-ruby-tracking.git'
gem 'newrelic_rpm' # monitoring, used in Wiki Ed Production mostly
gem 'skylight' # Rails-specific performance monitoring, used in Wiki Ed Production

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
# TZ information is not available on Windows, needs to be installed separately
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw]
# for those who don't have a native readline utility installed
gem 'rb-readline', platforms: [:mingw, :mswin, :x64_mingw]

### Incoming Mail
gem 'griddler'
gem 'griddler-mailgun'

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
  gem 'rails-erd'
  gem 'annotate' # Generates automatic schema notations on model files
  gem 'faker', require: false # Generates random data for example records
end

group :development, :test do
  gem 'pry-rails'
  gem 'byebug'
  gem 'rspec-rails'
  gem 'rubocop',  require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec-focused', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-performance', require: false
  gem 'factory_bot_rails' # Factory for creating ActiveRecord objects in tests
end

group :test do
  gem 'puma'
  gem 'rake', '>= 11.0'
  gem 'capybara'
  gem 'capybara-screenshot'
  gem 'webdrivers' # automatable browser drivers used by Capybara
  gem 'selenium-webdriver' # Capypara feature specs driven by headless Chrome
  gem 'webmock'
  gem 'vcr' # Saves external web requests and replays them in tests
  gem 'simplecov', require: false
  gem 'shoulda-matchers'
  gem 'rails-controller-testing'
end
