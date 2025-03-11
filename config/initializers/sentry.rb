Sentry.init do |config|
  config.dsn = ENV['sentry_dsn']
  config.enabled_environments = %w[development staging production test]
  config.traces_sample_rate = 1.0
end
