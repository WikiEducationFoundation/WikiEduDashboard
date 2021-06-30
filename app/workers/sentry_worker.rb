# frozen_string_literal: true

class SentryWorker
  include Sidekiq::Worker

  def perform(event)
    Sentry.send_event(event) if defined?(Sentry)
  end
end
