# frozen_string_literal: true

require_dependency "#{Rails.root}/app/services/score_detector_comparison_core"

# Scores one chunk of a detector comparison core run, then queues the next
# chunk. Started by ScoreDetectorComparisonCore.start; the run's state lives in
# a Setting, and each job carries its run's id, so a job from a replaced run
# exits without doing anything.
class ScoreDetectorComparisonCoreWorker
  include Sidekiq::Worker
  # Off the default queue, whose production process runs one job at a time and
  # carries the AI edit alert checks. Each call bills, and the service records
  # why a chunk failed, so no retries. The lock is released when a job starts, so
  # it can queue its successor.
  sidekiq_options queue: 'report_csv', retry: 0, lock: :until_executing

  def perform(run_id)
    self.class.perform_async(run_id) if ScoreDetectorComparisonCore.step(run_id)
  end
end
