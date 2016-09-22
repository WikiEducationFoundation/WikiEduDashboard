source 'https://rubygems.org'
ruby '2.3.1'
gem 'rails', '5.0.0.1'
gem 'jbuilder', '~> 2.0'
gem 'haml-rails'

gem 'mediawiki_api', '0.7.0'
gem 'crack'
gem 'figaro'
gem 'whenever'
gem 'mysql2'
gem 'activerecord-import'

gem 'browser'

gem 'devise'
gem 'omniauth-mediawiki', git: 'https://github.com/ragesoss/omniauth-mediawiki.git'

gem 'validates_email_format_of'

gem 'deep_cloneable', '~> 2.2.1'

gem 'sentry-raven'
gem 'piwik_analytics', git: 'https://github.com/halfdan/piwik-ruby-tracking.git'
gem 'newrelic_rpm'

gem 'redcarpet'
gem 'breadcrumbs_on_rails'
gem 'hashugar'

gem 'simple_form'

gem 'acts_as_list'

gem 'sentimental'

# used for enabling CSS for mailer emails
gem 'premailer-rails'
gem 'nokogiri' # expected by premailer-rails but not required

# UNIVERSAL TEXT CONVERTER - FOR MARDOWN TO MEDIAWIKI TEXT
gem 'pandoc-ruby', '~> 1.0.0'

gem 'http_accept_language'
gem 'i18n-js', '>= 3.0.0.rc14'

gem 'mailgun_rails'

gem 'factory_girl_rails'

gem 'paper_trail'

gem "paperclip", "~> 5.0.0"

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
  gem 'rack-mini-profiler'
  gem 'rails-erd'
  gem 'annotate', '~> 2.7.1'
end

group :development, :test do
  gem 'pry-rails'
  gem 'byebug'
  gem 'faker'
  gem 'rspec-rails'
  gem 'rubocop', require: false
  gem 'zeus'
  gem 'selenium-webdriver'
  gem 'launchy'
  gem 'timecop'
  gem 'poltergeist'
end

group :test do
  gem 'rake', '>= 11.0'
  gem 'capybara'
  gem 'capybara-webkit'
  gem 'capybara-screenshot'
  gem 'database_cleaner'
  gem 'webmock'
  gem 'vcr'
  gem 'simplecov', require: false
  gem 'codeclimate-test-reporter', require: nil
  gem 'shoulda-matchers', '~> 3.1'
  gem 'rails-controller-testing'
end

group :production do
  gem 'uglifier'
  gem 'rails_12factor'
end
