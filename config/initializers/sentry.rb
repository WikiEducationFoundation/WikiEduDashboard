Sentry.init do |config|
  config.dsn = ENV['sentry_dsn']
  config.enabled_environments = %w[development staging production test]
  config.traces_sample_rate = ENV['sentry_sample_rate'].to_f
end
