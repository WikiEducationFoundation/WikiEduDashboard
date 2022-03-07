# frozen_string_literal: true

class SentryWorker
  include Sidekiq::Worker

  def perform(event)
    return unless Features.wiki_ed?
    Sentry.send_event(event) if defined?(Sentry)
  end
end
