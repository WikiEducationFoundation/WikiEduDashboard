# frozen_string_literal: true

# Cron-driven dispatcher that enqueues a per-binding LtiRosterSyncWorker
# for every active LtiCourseBinding. "Active" means the bound Dashboard
# course's end date is in the recent past or future — we keep syncing for
# a 30-day grace period after course end so late-dropping students and
# late-grade pushes can still reconcile.
class LtiDailyRosterSyncWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed, queue: 'medium_update'

  GRACE_PERIOD = 30.days

  def perform
    LtiCourseBinding
      .joins(:course)
      .where('courses.end >= ?', Date.current - GRACE_PERIOD)
      .where.not(ltiaas_service_credentials: nil)
      .find_each do |binding|
        LtiRosterSyncWorker.perform_async(binding.id)
      end
  end
end
