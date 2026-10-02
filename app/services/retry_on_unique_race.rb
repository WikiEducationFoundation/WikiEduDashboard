# frozen_string_literal: true

# Find-then-create is not atomic. When two concurrent launches both find no row
# and the unique index refuses the loser's write, running the same block a second
# time — against the row the winner has now made visible — turns a 500 into an
# ordinary idempotent outcome. Once only: a second refusal is a real conflict,
# not a race, and belongs to the caller.
#
# Shared by LtiSession (bindings) and LtiLaunchLinker (identities), both of which
# write to tables under unique indexes on every launch.
module RetryOnUniqueRace
  private

  def retry_on_unique_race
    yield
  rescue ActiveRecord::RecordNotUnique
    yield
  end
end
