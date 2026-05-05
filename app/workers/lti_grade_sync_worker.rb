# frozen_string_literal: true

# Pushes LTIAAS AGS scores for one LtiCourseBinding. Wraps SyncLtiGrades.
# `lock: :until_executed` collapses concurrent enqueues so the periodic
# cron and on-demand triggers don't pile up. Sidekiq's retry handles
# transient LTIAAS failures.
class LtiGradeSyncWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed, retry: 5, queue: 'medium_update'

  def self.schedule(binding_id)
    perform_async(binding_id)
  end

  def perform(binding_id)
    binding = LtiCourseBinding.find_by(id: binding_id)
    return if binding.nil?

    SyncLtiGrades.new(binding)
  end
end
