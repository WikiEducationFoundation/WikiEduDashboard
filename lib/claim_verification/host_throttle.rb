# frozen_string_literal: true

module ClaimVerification
  # Keeps requests to any one host at least INTERVAL seconds apart, so that
  # fetching an article's sources doesn't hammer a publisher that many of its
  # citations point to. Not thread-safe; use one per fetching thread.
  class HostThrottle
    INTERVAL = 1.0

    def initialize(interval: INTERVAL)
      @interval = interval
      @last_request = {}
    end

    def wait(host)
      last = @last_request[host]
      if last
        remaining = @interval - (monotonic_now - last)
        sleep(remaining) if remaining.positive?
      end
      @last_request[host] = monotonic_now
    end

    private

    def monotonic_now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
