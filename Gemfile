source 'https://rubygems.org'
ruby '2.1.5'
gem 'rails', '4.2.4'
gem 'jbuilder', '~> 2.0'

gem 'mediawiki_api', '0.5.0'
gem 'crack'
gem 'figaro'
gem 'whenever'
gem 'mysql2', '~> 0.3.20'

gem 'browser'

gem 'devise'
gem 'omniauth-mediawiki'

gem 'deep_cloneable', '~> 2.1.1'

gem 'sentry-raven', '~>0.13.3'
gem 'piwik_analytics', git: 'https://github.com/halfdan/piwik-ruby-tracking.git'
gem 'newrelic_rpm'

# This fork has a fix for enums not working
# https://github.com/zdennis/activerecord-import/issues/139
gem 'activerecord-import', git: 'https://github.com/onemedical/activerecord-import.git'

# UNIVERSAL TEXT CONVERTER - FOR MARDOWN TO MEDIAWIKI TEXT
gem 'pandoc-ruby', '~> 1.0.0'

gem 'i18n-js', '>= 3.0.0.rc8'

group :development do
  gem 'pry-rails'
  gem 'better_errors'
  gem 'binding_of_caller', platforms: [:mri_21]
  gem 'guard-bundler'
  gem 'guard-rails'
  gem 'guard-rspec'
  gem 'quiet_assets'
  gem 'guard-livereload', require: false
  gem 'rb-fchange', require: false
  gem 'rb-fsevent', require: false
  gem 'rb-inotify', require: false
  gem 'capistrano-rvm'
  gem 'capistrano-rails'
  gem 'capistrano-bundler'
  gem 'capistrano-passenger'
  gem 'rack-mini-profiler'
  gem 'rails-erd'
  gem 'squeel', git: 'https://github.com/activerecord-hackery/squeel.git', branch: 'master'
  gem 'annotate', '~> 2.6.6'
end

group :development, :test do
  gem 'byebug'
  gem 'factory_girl_rails'
  gem 'faker'
  gem 'rspec-rails'
  gem 'rubocop', require: false
  gem 'zeus'
  gem 'selenium-webdriver'
  gem 'launchy'
end

group :test do
  gem 'rake'
  gem 'capybara'
  gem 'capybara-webkit'
  gem 'database_cleaner'
  gem 'webmock'
  gem 'vcr', github: 'vcr/vcr'
  gem 'simplecov', require: false
  gem 'codeclimate-test-reporter', require: nil
end
