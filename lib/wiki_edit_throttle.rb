# frozen_string_literal: true

#= Limits the Dashboard's edits per user per wiki (issue #7297), using a slot
#= in Redis shared by all processes.
class WikiEditThrottle
  # Most edits allowed in any 60 seconds.
  EDITS_PER_MINUTE = 19
  NEW_USER_EDITS_PER_MINUTE = 7
  # Edits that go through without waiting, so short jobs like an enrollment
  # don't sleep; the steady rate is lowered to keep each minute under its limit.
  BURST = 3

  # Atomically claims the next slot and returns the wait in milliseconds. Slots
  # are an interval apart; the first BURST of them need no wait (the GCRA
  # rate-limiting algorithm).
  RESERVE_SLOT = <<~LUA
    local now = tonumber(ARGV[1])
    local interval = tonumber(ARGV[2])
    local slot = math.max(tonumber(redis.call('GET', KEYS[1]) or 0), now)
    local next_slot = slot + interval
    redis.call('SET', KEYS[1], next_slot, 'PX', next_slot - now)
    return math.max(slot - (#{BURST} - 1) * interval - now, 0)
  LUA

  def self.wait_for_turn(user:, wiki:, autoconfirmed:)
    per_minute = autoconfirmed ? EDITS_PER_MINUTE : NEW_USER_EDITS_PER_MINUTE
    interval_ms = (60_000.0 / (per_minute - BURST + 1)).ceil
    wait_ms = reserve_slot("wiki_edit_throttle:#{wiki.id}:#{user.id}", interval_ms)
    sleep(wait_ms / 1000.0) if wait_ms.positive?
  end

  def self.reserve_slot(key, interval_ms)
    Sidekiq.redis do |redis|
      redis.call('EVAL', RESERVE_SLOT, 1, key, now_ms(redis), interval_ms)
    end
  end

  # Redis's clock, so web and Sidekiq hosts share one.
  def self.now_ms(redis)
    seconds, microseconds = redis.call('TIME')
    (seconds.to_i * 1000) + (microseconds.to_i / 1000)
  end
  private_class_method :reserve_slot, :now_ms
end
