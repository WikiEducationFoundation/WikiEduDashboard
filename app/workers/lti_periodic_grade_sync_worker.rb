# frozen_string_literal: true

# Cron-driven dispatcher: enqueues a per-binding LtiGradeSyncWorker for
# every active LtiCourseBinding. "Active" means the bound course's end
# date is within a 7-day grace period (covers ongoing courses + late
# completions).
#
# Cap of 50 enqueues per cycle keeps a single tick from filling the
# queue. Bindings beyond the cap pick up next tick (every 30 minutes,
# so all bindings get serviced quickly even at high volume).
class LtiPeriodicGradeSyncWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed, queue: 'medium_update'

  GRACE_PERIOD = 7.days
  PER_CYCLE_LIMIT = 50

  def perform
    eligible_bindings.limit(PER_CYCLE_LIMIT).each do |binding|
      LtiGradeSyncWorker.perform_async(binding.id)
    end
  end

  private

  def eligible_bindings
    LtiCourseBinding
      .joins(:course)
      .where('courses.end >= ?', Date.current - GRACE_PERIOD)
      .where.not(ltiaas_service_credentials: nil)
      .order(Arel.sql('COALESCE(last_grade_sync_at, "1970-01-01") ASC'))
  end
end
