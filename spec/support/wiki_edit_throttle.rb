# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_edit_throttle"

# Left on, WikiEditThrottle would make every spec that posts several edits for
# one user really sleep between them, and leave slots in Redis for later specs
# to wait on. Specs run with it off; tag an example group
# `:real_wiki_edit_throttle` to exercise it. Its sleeps then move the clock
# forward instead of waiting, and its slots are cleared afterwards.
RSpec.configure do |config|
  config.before do |example|
    next if example.metadata[:real_wiki_edit_throttle]
    allow(WikiEditThrottle).to receive(:wait_for_turn)
  end

  # The clock starts frozen so a spec's first timestamp is exactly when its
  # first slot was claimed, not a few milliseconds of real time later.
  config.before(:each, :real_wiki_edit_throttle) do
    freeze_time
    allow(WikiEditThrottle).to receive(:sleep) { |seconds| travel(seconds, with_usec: true) }
  end

  config.after(:each, :real_wiki_edit_throttle) do
    Sidekiq.redis do |redis|
      keys = redis.call('KEYS', 'wiki_edit_throttle:*')
      redis.call('DEL', *keys) if keys.any?
    end
  end
end
