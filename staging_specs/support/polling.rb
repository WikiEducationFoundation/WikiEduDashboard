# frozen_string_literal: true

# Small retry helper for the score specs. A successful AGS score POST
# returns before Canvas has necessarily surfaced the resulting submission
# through its REST API, and the AGS line-item create lands a moment before
# the matching assignment is queryable. `eventually` re-runs its block
# until it returns a truthy value (or attempts run out), so the score
# specs don't flake on that brief lag. Returns the block's value, or nil
# if it never became truthy.
module StagingPolling
  def eventually(attempts: 8, interval: 2)
    attempts.times do |i|
      value = yield
      return value if value

      sleep interval if i < attempts - 1
    end
    nil
  end
end
