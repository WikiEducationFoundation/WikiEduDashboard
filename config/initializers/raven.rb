require 'raven'

Raven.configure do |config|
  config.dsn = Figaro.env.sentry_dsn
end
