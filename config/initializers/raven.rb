require 'raven'

Raven.configure do |config|
  config.dsn = Figaro.env.sentry_dsn
  config.silence_ready = true
  config.environments = %w[development staging production]
  config.logger = Logger.new("/dev/null")
end
