require 'raven'
require 'raven/transports/dummy' if Rails.env.test?
is_on_windows = (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil

Raven.configure do |config|
  config.dsn = ENV['sentry_dsn']
  config.silence_ready = true
  config.environments = %w[development staging production test]
  config.logger = Logger.new("/dev/null") unless is_on_windows
  config.logger = Logger.new("nul") if is_on_windows
end
