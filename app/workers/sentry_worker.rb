# frozen_string_literal: true

class SentryWorker
  include Sidekiq::Worker

  def perform(event)
    Raven.send_event(event) if defined?(Raven)
  end
end
