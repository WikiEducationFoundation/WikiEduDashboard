# frozen_string_literal: true

class SentryWorker
  include Sidekiq::Worker
  sidekiq_options retry: 0

  def perform(event)
    Sentry.send_event(event) if defined?(Sentry)
  end
end
