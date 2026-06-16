# frozen_string_literal: true

# Scheduled (sidekiq-cron, see config/schedule.yml) population of the
# claim-verification exercise pool. The lock prevents a slow, API-bound run
# from overlapping with the next scheduled one.
class HarvestVerificationClaimPoolWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def perform
    HarvestVerificationClaimPool.new
  end
end
