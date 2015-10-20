require 'raven'

unless Figaro.env.sentry_dsn.empty?

  Raven.configure do |config|
    config.dsn = Figaro.env.sentry_dsn
    config.silence_ready = true
  end

end