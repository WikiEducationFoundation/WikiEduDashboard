Sentry.init do |config|
  config.dsn = ENV['sentry_dsn']
  config.enabled_environments = %w[development staging production test]
  config.async = lambda { |event| SentryWorker.perform_async(event.to_hash) }
end
