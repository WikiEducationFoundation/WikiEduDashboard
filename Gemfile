source 'https://rubygems.org'
ruby '2.1.5'
gem 'rails', '4.1.8'
gem 'jbuilder', '~> 2.0'

gem 'mediawiki-gateway'
gem 'crack'
gem 'figaro'
gem 'whenever'

group :development do
  gem 'better_errors'
  gem 'binding_of_caller', :platforms=>[:mri_21]
  gem 'guard-bundler'
  gem 'guard-rails'
  gem 'guard-rspec'
  gem 'quiet_assets'
  gem 'guard-livereload', :require=>false
  gem 'rb-fchange', :require=>false
  gem 'rb-fsevent', :require=>false
  gem 'rb-inotify', :require=>false
end

group :development, :test do
  gem 'byebug'
  gem 'factory_girl_rails'
  gem 'faker'
  gem 'rspec-rails'
  gem 'rubocop'
  gem 'sqlite3'
  gem 'zeus'
end

group :production do
  gem 'pg'
  gem 'rails_12factor'
end

group :test do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'webmock'
  gem 'vcr', github: 'vcr/vcr'
end
