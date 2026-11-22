# frozen_string_literal: true

#= Limits the Dashboard's edits per user per wiki (issue #7297), using a slot
#= in Redis shared by all processes.
class WikiEditThrottle
  EDITS_PER_MINUTE = 19
  NEW_USER_EDITS_PER_MINUTE = 7

  # Atomically claims the next free slot; returns the wait in milliseconds.
  RESERVE_SLOT = <<~LUA
    local now = tonumber(ARGV[1])
    local slot = math.max(tonumber(redis.call('GET', KEYS[1]) or 0), now)
    local next_slot = slot + tonumber(ARGV[2])
    redis.call('SET', KEYS[1], next_slot, 'PX', next_slot - now)
    return slot - now
  LUA

  def self.wait_for_turn(user:, wiki:, autoconfirmed:)
    per_minute = autoconfirmed ? EDITS_PER_MINUTE : NEW_USER_EDITS_PER_MINUTE
    interval_ms = (60_000.0 / per_minute).ceil
    wait_ms = reserve_slot("wiki_edit_throttle:#{wiki.id}:#{user.id}", interval_ms)
    sleep(wait_ms / 1000.0) if wait_ms.positive?
  end

  def self.reserve_slot(key, interval_ms)
    now_ms = (Time.now.to_f * 1000).round
    Sidekiq.redis do |redis|
      redis.call('EVAL', RESERVE_SLOT, 1, key, now_ms, interval_ms)
    end
  end
  private_class_method :reserve_slot
end
