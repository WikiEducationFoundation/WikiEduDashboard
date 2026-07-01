# frozen_string_literal: true

require_dependency "#{Rails.root}/app/services/harvest_claim_pool"

# Runs a claim-pool harvest in the background, surfacing live progress through
# Sidekiq::Status so the admin page can poll it. lock: :until_executed prevents
# overlapping harvests — the harvest makes one parser API call per alert and is
# kept serial on purpose. retry: 0 so a failed harvest doesn't silently re-run.
class HarvestClaimPoolWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  # A long, manually-triggered batch — runs on the daily_update queue so it
  # never competes with the every-4-minutes constant_update cycle.
  sidekiq_options queue: 'daily_update', retry: 0, lock: :until_executed

  # Enqueues a harvest and stashes the job id so the status endpoint can find it.
  def self.harvest(full_rescan: false)
    job_id = perform_async(full_rescan)
    Setting.set_hash(HarvestClaimPool::SETTING_KEY, 'job_id', job_id)
    job_id
  end

  def perform(full_rescan = false)
    store(worker: self.class.name, full_rescan:, phase: 'harvesting')
    HarvestClaimPool.new(full_rescan:, total: method(:total),
                         at: method(:at), store: method(:store))
  end
end
