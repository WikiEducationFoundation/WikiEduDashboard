# frozen_string_literal: true

# Reports progress of an in-flight course update through sidekiq-status, so
# that an external view (or JSON endpoint) can show which pipeline phase the
# job is in and — for phases with quantifiable work — how far through it is.
#
# Threaded from CourseDataUpdateWorker into UpdateCourseStats and from there
# into the slower inner services (timeslices, uploads). When constructed with
# a nil worker (e.g. from a spec or a non-sidekiq caller) every method is a
# no-op, so call sites don't need conditional guards.
#
# Also handles pausing the worker while a database backup is running; this
# behavior was previously in LogSidekiqStatus.
class UpdateProgressReporter
  SLEEP_TIME_IN_SECONDS = 60
  INITIAL_PHASE = 'initialization'

  def initialize(worker = nil)
    @worker = worker
    @sleep_count = 0
    return unless @worker
    now = Time.now.to_i
    @worker.store(started_at: now, phase: INITIAL_PHASE, phase_started_at: now)
  end

  # Marks the start of a new pipeline phase. Resets any numeric progress
  # left over from the previous phase so stale at/total values don't bleed
  # through. Pass `total:` when the new phase has a knowable work total.
  def phase(name, total: nil)
    return unless @worker
    @worker.store(phase: name.to_s, phase_started_at: Time.now.to_i,
                  at: 0, total: 0, pct_complete: 0, message: '')
    @worker.total(total || 0)
  end

  # Reports progress within the current phase. `total:` is optional after
  # the first call; pass it again if the total grows (e.g. timeslices split
  # adaptively during processing).
  def progress(at:, total: nil, message: nil)
    return unless @worker
    @worker.total(total) if total
    @worker.at(at, message)
  end

  # Blocks until any in-progress DB backup has finished. Sidekiq workers
  # call this at the start of an update to avoid contending with the backup.
  def pause_until_no_backup
    pause until Backup.current_backup.nil?
    @worker&.store(phase: 'woke_up')
  end

  private

  def pause
    @sleep_count += 1
    @worker&.store(phase: "sleeping_#{@sleep_count}")
    sleep SLEEP_TIME_IN_SECONDS
  end
end
