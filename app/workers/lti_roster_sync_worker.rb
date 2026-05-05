# frozen_string_literal: true

# Pulls the LMS roster for a single LtiCourseBinding via NRPS and
# reconciles each member with the Dashboard's LtiContext table.
#
# `lock: :until_executed` (sidekiq-unique-jobs) collapses redundant
# enqueues so on-launch fire-and-forget plus the daily cron don't pile up.
# Sidekiq's built-in retry handles transient LTIAAS failures
# (LtiaasTransientError, LtiaasRateLimitError); authoritative failures
# (LtiaasClientError, LtiaasAuthError) bubble up and dead-letter.
class LtiRosterSyncWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed, retry: 5, queue: 'medium_update'

  def self.schedule(binding_id)
    perform_async(binding_id)
  end

  def perform(binding_id)
    binding = LtiCourseBinding.find_by(id: binding_id)
    return if binding.nil?

    SyncLtiRoster.new(binding)
  end
end
