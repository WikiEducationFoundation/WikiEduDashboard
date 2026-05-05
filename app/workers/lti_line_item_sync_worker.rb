# frozen_string_literal: true

# Reconciles a single LtiCourseBinding's LTIAAS gradebook line items with
# the bound Dashboard course timeline. Triggered:
#
#   - On instructor binding completion (LtiLaunchController#complete_setup)
#   - On wizard finish (post-WizardController hook)
#   - On Block save (debounced after-commit hook on Block)
#   - As a precondition inside LtiGradeSyncWorker (PR 5)
#
# `lock: :until_executed` collapses the bursty enqueues from wizard +
# block-edit hooks. Sidekiq's retry handles transient LTIAAS failures.
class LtiLineItemSyncWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed, retry: 5, queue: 'medium_update'

  def self.schedule(binding_id)
    perform_async(binding_id)
  end

  def perform(binding_id)
    binding = LtiCourseBinding.find_by(id: binding_id)
    return if binding.nil?

    SyncLtiLineItems.new(binding)
  end
end
