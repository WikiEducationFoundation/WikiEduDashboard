source 'https://rubygems.org'
ruby '2.1.5'
gem 'rails', '4.2.5'
gem 'jbuilder', '~> 2.0'
gem 'haml-rails'

gem 'mediawiki_api', '0.5.0'
gem 'crack'
gem 'figaro'
gem 'whenever'
gem 'mysql2'
gem 'activerecord-import'

gem 'browser'

gem 'devise'
gem 'omniauth-mediawiki', git: 'https://github.com/ragesoss/omniauth-mediawiki.git'

gem 'deep_cloneable', '~> 2.1.1'

gem 'sentry-raven', '~>0.13.3'
gem 'piwik_analytics', git: 'https://github.com/halfdan/piwik-ruby-tracking.git'
gem 'newrelic_rpm'

gem 'redcarpet'
gem 'breadcrumbs_on_rails'

# master branch contains Nick's patch that silences warnings on ruby >= 2.0.0
gem 'hashugar', git: 'https://github.com/jsuchal/hashugar.git', branch: 'master'

# UNIVERSAL TEXT CONVERTER - FOR MARDOWN TO MEDIAWIKI TEXT
gem 'pandoc-ruby', '~> 1.0.0'

gem 'i18n-js', '>= 3.0.0.rc11'

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
  gem 'timecop'
end

group :test do
  gem 'rake'
  gem 'capybara'
  gem 'capybara-webkit'
  gem 'capybara-screenshot'
  gem 'database_cleaner'
  gem 'webmock'
  gem 'vcr'
  gem 'simplecov', require: false
  gem 'codeclimate-test-reporter', require: nil
end
