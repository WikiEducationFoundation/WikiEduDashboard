# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = ENV['sentry_dsn']
  config.enabled_environments = %w[development staging production test]

  # Appends to IGNORE_DEFAULT array of exception classes that should never be sent to Sentry
  config.excluded_exceptions += ['Errors::PageContentErrors::NilPageContentError']
end
